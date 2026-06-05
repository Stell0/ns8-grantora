<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row v-if="userDomainDiscoveryError">
      <cv-column>
        <NsInlineNotification
          kind="warning"
          :title="$t('settings.user_domain_discovery')"
          :description="userDomainDiscoveryError"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <section class="settings-section">
              <h4>{{ $t("settings.public_route") }}</h4>
              <cv-row>
                <cv-column :md="4" :max="5">
                  <cv-text-input
                    :label="$t('settings.host')"
                    v-model.trim="host"
                    :placeholder="$t('settings.host_placeholder')"
                    :disabled="loadingUi"
                    :invalid-message="error.host"
                    ref="host"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="8" :max="7">
                  <NsToggle
                    value="letsEncrypt"
                    :label="$t('settings.lets_encrypt')"
                    v-model="letsEncryptEnabled"
                    :disabled="loadingUi"
                  >
                    <template slot="text-left">
                      {{ $t("common.disabled") }}
                    </template>
                    <template slot="text-right">
                      {{ $t("common.enabled") }}
                    </template>
                  </NsToggle>
                </cv-column>
              </cv-row>
            </section>

            <section class="settings-section">
              <h4>{{ $t("settings.runtime_image") }}</h4>
              <cv-row>
                <cv-column :md="4" :max="4">
                  <NsComboBox
                    v-model="logLevel"
                    :options="logLevelOptions"
                    :title="$t('settings.log_level')"
                    :label="$t('settings.choose_log_level')"
                    :disabled="loadingUi"
                    auto-highlight
                  />
                </cv-column>
              </cv-row>
              <cv-row>
                <cv-column class="checkbox-column">
                  <cv-checkbox
                    v-model="metricsEnabled"
                    :label="$t('settings.metrics_enabled')"
                    :disabled="loadingUi"
                  />
                </cv-column>
              </cv-row>
            </section>

            <section class="settings-section">
              <h4>{{ $t("settings.user_provider") }}</h4>
              <cv-row>
                <cv-column :md="4" :max="5">
                  <NsComboBox
                    v-model="userDomain"
                    :options="domainOptions"
                    :title="$t('settings.user_domain')"
                    :label="$t('settings.choose_user_domain')"
                    :disabled="loadingUi || !domainOptions.length"
                    :invalid-message="error.userDomain"
                    auto-highlight
                    ref="userDomain"
                  />
                </cv-column>
                <cv-column :md="4" :max="3" class="checkbox-column">
                  <cv-checkbox
                    v-model="syncUsersEnabled"
                    :label="$t('settings.sync_users_enabled')"
                    :disabled="loadingUi"
                  />
                </cv-column>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.sync_users_interval_minutes')"
                    v-model.number="syncUsersIntervalMinutes"
                    :disabled="loadingUi || !syncUsersEnabled"
                    :invalid-message="error.syncUsersIntervalMinutes"
                    ref="syncUsersIntervalMinutes"
                  ></cv-text-input>
                </cv-column>
              </cv-row>
            </section>

            <section class="settings-section">
              <h4>{{ $t("settings.runtime_policy") }}</h4>
              <cv-row>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.runtime_rate_limit_count')"
                    v-model.number="runtimeRateLimitCount"
                    :disabled="loadingUi"
                    :invalid-message="error.runtimeRateLimitCount"
                    ref="runtimeRateLimitCount"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.runtime_rate_limit_time_window')"
                    v-model.number="runtimeRateLimitTimeWindow"
                    :disabled="loadingUi"
                    :invalid-message="error.runtimeRateLimitTimeWindow"
                    ref="runtimeRateLimitTimeWindow"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.audit_retention_days')"
                    v-model.number="auditRetentionDays"
                    :disabled="loadingUi"
                    :invalid-message="error.auditRetentionDays"
                    ref="auditRetentionDays"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.usage_retention_days')"
                    v-model.number="usageRetentionDays"
                    :disabled="loadingUi"
                    :invalid-message="error.usageRetentionDays"
                    ref="usageRetentionDays"
                  ></cv-text-input>
                </cv-column>
              </cv-row>
            </section>

            <section class="settings-section">
              <h4>{{ $t("settings.upstream_defaults") }}</h4>
              <cv-row>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.upstream_timeout_seconds')"
                    v-model.number="upstreamTimeoutSeconds"
                    :disabled="loadingUi"
                    :invalid-message="error.upstreamTimeoutSeconds"
                    ref="upstreamTimeoutSeconds"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.upstream_connect_timeout_seconds')"
                    v-model.number="upstreamConnectTimeoutSeconds"
                    :disabled="loadingUi"
                    :invalid-message="error.upstreamConnectTimeoutSeconds"
                    ref="upstreamConnectTimeoutSeconds"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.upstream_max_response_bytes')"
                    v-model.number="upstreamMaxResponseBytes"
                    :disabled="loadingUi"
                    :invalid-message="error.upstreamMaxResponseBytes"
                    ref="upstreamMaxResponseBytes"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="4" :max="4">
                  <cv-text-input
                    :label="$t('settings.upstream_read_retry_attempts')"
                    v-model.number="upstreamReadRetryAttempts"
                    :disabled="loadingUi"
                    :invalid-message="error.upstreamReadRetryAttempts"
                    ref="upstreamReadRetryAttempts"
                  ></cv-text-input>
                </cv-column>
                <cv-column :md="4" :max="4" class="checkbox-column">
                  <cv-checkbox
                    v-model="upstreamTlsVerify"
                    :label="$t('settings.upstream_tls_verify')"
                    :disabled="loadingUi"
                  />
                </cv-column>
              </cv-row>
            </section>

            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loadingUi"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";
import GrantoraAdminMixin from "../mixins/GrantoraAdminMixin";

const HOST_PATTERN =
  /^(?=.{1,253}$)(?!-)[A-Za-z0-9-]{1,63}(?<!-)(\.(?!-)[A-Za-z0-9-]{1,63}(?<!-))+$/;

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
    GrantoraAdminMixin,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      urlCheckInterval: null,
      host: "",
      letsEncryptEnabled: true,
      logLevel: "INFO",
      metricsEnabled: false,
      userDomain: "-",
      userDomains: [],
      userDomainDiscoveryError: "",
      syncUsersEnabled: false,
      syncUsersIntervalMinutes: 60,
      runtimeRateLimitCount: 1000,
      runtimeRateLimitTimeWindow: 60,
      auditRetentionDays: 365,
      usageRetentionDays: 365,
      upstreamTlsVerify: true,
      upstreamTimeoutSeconds: 30,
      upstreamConnectTimeoutSeconds: 10,
      upstreamMaxResponseBytes: 10485760,
      upstreamReadRetryAttempts: 2,
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: this.emptyErrors(),
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    loadingUi() {
      return this.loading.getConfiguration || this.loading.configureModule;
    },
    domainOptions() {
      const domains = this.userDomains.map((domain) => ({
        name: domain.name,
        label: this.domainLabel(domain),
        value: domain.name,
      }));
      domains.unshift({
        name: "no_user_domain",
        label: this.$t("settings.no_user_domain"),
        value: "-",
      });
      return domains;
    },
    logLevelOptions() {
      return ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"].map((level) => ({
        name: level,
        label: level,
        value: level,
      }));
    },
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  created() {
    this.getConfiguration();
  },
  methods: {
    emptyErrors() {
      return {
        getConfiguration: "",
        configureModule: "",
        host: "",
        userDomain: "",
        syncUsersIntervalMinutes: "",
        runtimeRateLimitCount: "",
        runtimeRateLimitTimeWindow: "",
        auditRetentionDays: "",
        usageRetentionDays: "",
        upstreamTimeoutSeconds: "",
        upstreamConnectTimeoutSeconds: "",
        upstreamMaxResponseBytes: "",
        upstreamReadRetryAttempts: "",
      };
    },
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";

      await this.runGrantoraAction(taskAction, {
        isNotificationHidden: true,
        onCompleted: this.getConfigurationCompleted,
        onAborted: this.getConfigurationAborted,
        onError: (err) => {
          this.error.getConfiguration = this.getErrorMessage(err);
          this.loading.getConfiguration = false;
        },
      });
    },
    getConfigurationAborted() {
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      this.loading.getConfiguration = false;
      const config = taskResult.output;
      this.host = config.host || "";
      this.letsEncryptEnabled = config.lets_encrypt !== false;
      this.logLevel = config.log_level || "INFO";
      this.metricsEnabled = Boolean(config.metrics_enabled);
      this.userDomains = config.available_user_domains || [];
      this.userDomainDiscoveryError = config.user_domain_discovery_error || "";
      this.userDomain = config.ldap_user_domain || "-";
      this.syncUsersEnabled = Boolean(config.sync_users_enabled);
      this.syncUsersIntervalMinutes = config.sync_users_interval_minutes || 60;
      this.runtimeRateLimitCount = config.runtime_rate_limit_count || 1000;
      this.runtimeRateLimitTimeWindow =
        config.runtime_rate_limit_time_window || 60;
      this.auditRetentionDays = config.audit_retention_days || 365;
      this.usageRetentionDays = config.usage_retention_days || 365;
      this.upstreamTlsVerify = config.upstream_tls_verify !== false;
      this.upstreamTimeoutSeconds = config.upstream_timeout_seconds || 30;
      this.upstreamConnectTimeoutSeconds =
        config.upstream_connect_timeout_seconds || 10;
      this.upstreamMaxResponseBytes =
        config.upstream_max_response_bytes || 10485760;
      this.upstreamReadRetryAttempts = Number.isInteger(
        config.upstream_read_retry_attempts
      )
        ? config.upstream_read_retry_attempts
        : 2;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.error = this.emptyErrors();
      let isValidationOk = true;
      const focusFirst = (field) => {
        if (isValidationOk) {
          this.focusElement(field);
          isValidationOk = false;
        }
      };

      if (!this.host) {
        this.error.host = this.$t("common.required");
        focusFirst("host");
      } else if (!HOST_PATTERN.test(this.host)) {
        this.error.host = this.$t("settings.invalid_host");
        focusFirst("host");
      }
      if (this.syncUsersEnabled && this.userDomain === "-") {
        this.error.userDomain = this.$t("common.required");
        focusFirst("userDomain");
      }

      this.validateInteger(
        "syncUsersIntervalMinutes",
        this.syncUsersIntervalMinutes,
        1,
        1440,
        focusFirst
      );
      this.validateInteger(
        "runtimeRateLimitCount",
        this.runtimeRateLimitCount,
        1,
        1000000,
        focusFirst
      );
      this.validateInteger(
        "runtimeRateLimitTimeWindow",
        this.runtimeRateLimitTimeWindow,
        1,
        86400,
        focusFirst
      );
      this.validateInteger(
        "auditRetentionDays",
        this.auditRetentionDays,
        1,
        3650,
        focusFirst
      );
      this.validateInteger(
        "usageRetentionDays",
        this.usageRetentionDays,
        1,
        3650,
        focusFirst
      );
      this.validateInteger(
        "upstreamTimeoutSeconds",
        this.upstreamTimeoutSeconds,
        1,
        600,
        focusFirst
      );
      this.validateInteger(
        "upstreamConnectTimeoutSeconds",
        this.upstreamConnectTimeoutSeconds,
        1,
        120,
        focusFirst
      );
      this.validateInteger(
        "upstreamMaxResponseBytes",
        this.upstreamMaxResponseBytes,
        1,
        1073741824,
        focusFirst
      );
      this.validateInteger(
        "upstreamReadRetryAttempts",
        this.upstreamReadRetryAttempts,
        0,
        10,
        focusFirst
      );
      return isValidationOk;
    },
    validateInteger(field, value, minimum, maximum, focusFirst) {
      const parsed = Number(value);
      if (!Number.isInteger(parsed) || parsed < minimum || parsed > maximum) {
        this.error[field] = this.$t("common.integer_range", {
          minimum,
          maximum,
        });
        focusFirst(field);
      }
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      const fieldMap = {
        user_domain: "userDomain",
        sync_users_interval_minutes: "syncUsersIntervalMinutes",
        runtime_rate_limit_count: "runtimeRateLimitCount",
        runtime_rate_limit_time_window: "runtimeRateLimitTimeWindow",
        audit_retention_days: "auditRetentionDays",
        usage_retention_days: "usageRetentionDays",
        upstream_timeout_seconds: "upstreamTimeoutSeconds",
        upstream_connect_timeout_seconds: "upstreamConnectTimeoutSeconds",
        upstream_max_response_bytes: "upstreamMaxResponseBytes",
        upstream_read_retry_attempts: "upstreamReadRetryAttempts",
      };
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const field = fieldMap[validationError.field] || validationError.field;

        if (field !== "(root)" && this.error[field] !== undefined) {
          this.error[field] = this.$t("error.validation_error");

          if (!focusAlreadySet) {
            this.focusElement(field);
            focusAlreadySet = true;
          }
        } else {
          this.error.configureModule = this.$t("error.validation_error");
        }
      }
    },
    async configureModule() {
      if (!this.validateConfigureModule()) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";

      await this.runGrantoraAction(taskAction, {
        data: {
          host: this.host,
          lets_encrypt: this.letsEncryptEnabled,
          metrics_enabled: this.metricsEnabled,
          log_level: this.logLevel,
          user_domain: this.userDomain === "-" ? "" : this.userDomain,
          sync_users_enabled: this.syncUsersEnabled,
          sync_users_interval_minutes: Number(this.syncUsersIntervalMinutes),
          runtime_rate_limit_count: Number(this.runtimeRateLimitCount),
          runtime_rate_limit_time_window: Number(
            this.runtimeRateLimitTimeWindow
          ),
          audit_retention_days: Number(this.auditRetentionDays),
          usage_retention_days: Number(this.usageRetentionDays),
          upstream_tls_verify: this.upstreamTlsVerify,
          upstream_timeout_seconds: Number(this.upstreamTimeoutSeconds),
          upstream_connect_timeout_seconds: Number(
            this.upstreamConnectTimeoutSeconds
          ),
          upstream_max_response_bytes: Number(this.upstreamMaxResponseBytes),
          upstream_read_retry_attempts: Number(this.upstreamReadRetryAttempts),
        },
        title: this.$t("settings.configure_instance", {
          instance: this.instanceName,
        }),
        description: this.$t("common.processing"),
        onCompleted: this.configureModuleCompleted,
        onAborted: this.configureModuleAborted,
        onValidationFailed: this.configureModuleValidationFailed,
        onError: (err) => {
          this.error.configureModule = this.getErrorMessage(err);
          this.loading.configureModule = false;
        },
      });
    },
    configureModuleAborted() {
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;
      this.getConfiguration();
    },
    domainLabel(domain) {
      const parts = [domain.name];
      if (domain.schema) {
        parts.push(domain.schema);
      }
      if (domain.provider_module) {
        parts.push(domain.provider_module);
      }
      if (domain.reachable === false) {
        parts.push(this.$t("settings.unreachable"));
      }
      return parts.join(" - ");
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";

.settings-section {
  margin-bottom: $spacing-07;
}

.settings-section h4 {
  margin-bottom: $spacing-05;
}

.checkbox-column {
  display: flex;
  align-items: flex-end;
  min-height: 4.5rem;
}
</style>
