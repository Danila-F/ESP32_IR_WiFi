#include <stdbool.h>
#include <stdio.h>

#include "esp_event.h"
#include "esp_log.h"
#include "esp_netif.h"
#include "esp_wifi.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/event_groups.h"
#include "nvs_flash.h"

#ifndef WIFI_SSID
#define WIFI_SSID ""
#endif

#ifndef WIFI_PASSWORD
#define WIFI_PASSWORD ""
#endif

#ifndef STATUS_LED_GPIO
#define STATUS_LED_GPIO GPIO_NUM_2
#endif

#ifndef STATUS_LED_ACTIVE_LEVEL
#define STATUS_LED_ACTIVE_LEVEL 1
#endif

#define WIFI_CONNECTED_BIT BIT0
#define WIFI_FAIL_BIT BIT1
#define WIFI_MAXIMUM_RETRY 5
#define STATUS_LED_BLINK_DELAY_MS 500

static const char *TAG = "wifi_station";
static EventGroupHandle_t wifi_event_group;
static int wifi_retry_count = 0;

static void status_led_set(bool is_on) {
    int inactive_level = STATUS_LED_ACTIVE_LEVEL ? 0 : 1;
    int output_level = is_on ? STATUS_LED_ACTIVE_LEVEL : inactive_level;

    gpio_set_level(STATUS_LED_GPIO, output_level);
}

static void status_led_task(void *arg) {
    while (true) {
        EventBits_t bits = xEventGroupGetBits(wifi_event_group);

        if (bits & WIFI_CONNECTED_BIT) {
            status_led_set(true);
            vTaskDelete(NULL);
        }

        if (bits & WIFI_FAIL_BIT) {
            status_led_set(false);
            vTaskDelete(NULL);
        }

        status_led_set(true);
        vTaskDelay(pdMS_TO_TICKS(STATUS_LED_BLINK_DELAY_MS));
        status_led_set(false);
        vTaskDelay(pdMS_TO_TICKS(STATUS_LED_BLINK_DELAY_MS));
    }
}

static void init_status_led(void) {
    gpio_config_t led_config = {
        .pin_bit_mask = 1ULL << STATUS_LED_GPIO,
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };

    ESP_ERROR_CHECK(gpio_config(&led_config));
    status_led_set(false);
}

static void wifi_event_handler(void *arg,
                               esp_event_base_t event_base,
                               int32_t event_id,
                               void *event_data) {
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
        ESP_LOGI(TAG, "WiFi station started, connecting...");
        return;
    }

    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        if (wifi_retry_count < WIFI_MAXIMUM_RETRY) {
            esp_wifi_connect();
            wifi_retry_count++;
            ESP_LOGW(TAG, "Retrying WiFi connection (%d/%d)",
                     wifi_retry_count, WIFI_MAXIMUM_RETRY);
        } else {
            xEventGroupSetBits(wifi_event_group, WIFI_FAIL_BIT);
            ESP_LOGE(TAG, "Failed to connect to WiFi");
        }
        return;
    }

    if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        ip_event_got_ip_t *event = (ip_event_got_ip_t *)event_data;

        wifi_retry_count = 0;
        xEventGroupSetBits(wifi_event_group, WIFI_CONNECTED_BIT);
        ESP_LOGI(TAG, "Connected, IP address: " IPSTR, IP2STR(&event->ip_info.ip));
    }
}

static esp_err_t init_nvs(void) {
    esp_err_t err = nvs_flash_init();

    if (err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        err = nvs_flash_init();
    }

    return err;
}

static void wifi_init_sta(void) {
    wifi_event_group = xEventGroupCreate();
    xTaskCreate(status_led_task, "status_led_task", 2048, NULL, 1, NULL);

    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(
        esp_event_handler_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL));
    ESP_ERROR_CHECK(
        esp_event_handler_register(IP_EVENT, IP_EVENT_STA_GOT_IP, &wifi_event_handler, NULL));

    wifi_config_t wifi_config = {
        .sta =
            {
                .threshold.authmode = WIFI_AUTH_WPA2_PSK,
                .pmf_cfg =
                    {
                        .capable = true,
                        .required = false,
                    },
            },
    };

    snprintf((char *)wifi_config.sta.ssid, sizeof(wifi_config.sta.ssid), "%s", WIFI_SSID);
    snprintf((char *)wifi_config.sta.password, sizeof(wifi_config.sta.password), "%s",
             WIFI_PASSWORD);

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    EventBits_t bits = xEventGroupWaitBits(
        wifi_event_group,
        WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,
        pdFALSE,
        pdFALSE,
        portMAX_DELAY);

    if (bits & WIFI_CONNECTED_BIT) {
        ESP_LOGI(TAG, "WiFi connection established for SSID \"%s\"", WIFI_SSID);
    } else if (bits & WIFI_FAIL_BIT) {
        ESP_LOGE(TAG, "WiFi connection failed for SSID \"%s\"", WIFI_SSID);
    } else {
        ESP_LOGE(TAG, "Unexpected WiFi event");
    }
}

void app_main(void) {
    init_status_led();

    if (sizeof(WIFI_SSID) <= 1) {
        ESP_LOGE(TAG,
                 "WiFi credentials are not configured. Set WIFI_SSID and WIFI_PASSWORD in "
                 "platformio.ini build_flags.");
        return;
    }

    ESP_ERROR_CHECK(init_nvs());
    wifi_init_sta();

    while (true) {
        vTaskDelay(pdMS_TO_TICKS(10000));
    }
}
