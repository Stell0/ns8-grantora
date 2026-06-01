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
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.host')"
              v-model.trim="host"
              :placeholder="$t('settings.host_placeholder')"
              :disabled="loadingUi"
              :invalid-message="error.host"
              ref="host"
            ></cv-text-input>
            <cv-checkbox
              v-model="letsEncrypt"
              :label="$t('settings.lets_encrypt')"
              :disabled="loadingUi"
            />
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
            <cv-checkbox
              v-model="syncUsersEnabled"
              :label="$t('settings.sync_users_enabled')"
              :disabled="loadingUi"
            />
            <cv-text-input
              :label="$t('settings.sync_users_interval_minutes')"
              v-model.number="syncUsersIntervalMinutes"
              :disabled="loadingUi || !syncUsersEnabled"
              :invalid-message="error.syncUsersIntervalMinutes"
              ref="syncUsersIntervalMinutes"
            ></cv-text-input>
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
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
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
      letsEncrypt: true,
      userDomain: "-",
      userDomains: [],
      syncUsersEnabled: false,
      syncUsersIntervalMinutes: 60,
      loading: {
        getConfiguration: false,
        configureModule: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        userDomain: "",
        syncUsersIntervalMinutes: "",
      },
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
        label: domain.name,
        value: domain.name,
      }));
      domains.unshift({
        name: "no_user_domain",
        label: this.$t("settings.no_user_domain"),
        value: "-",
      });
      return domains;
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
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      this.loading.getConfiguration = false;
      const config = taskResult.output;
      this.host = config.host || "";
      this.letsEncrypt = Boolean(config.lets_encrypt);
      this.userDomains = config.available_user_domains || [];
      this.userDomain = config.ldap_user_domain || "-";
      this.syncUsersEnabled = Boolean(config.sync_users_enabled);
      this.syncUsersIntervalMinutes = config.sync_users_interval_minutes || 60;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      let isValidationOk = true;

      if (!this.host) {
        this.error.host = this.$t("common.required");

        if (isValidationOk) {
          this.focusElement("host");
          isValidationOk = false;
        }
      }
      if (this.syncUsersEnabled && this.userDomain === "-") {
        this.error.userDomain = this.$t("common.required");

        if (isValidationOk) {
          this.focusElement("userDomain");
          isValidationOk = false;
        }
      }
      if (
        this.syncUsersEnabled &&
        (!this.syncUsersIntervalMinutes || this.syncUsersIntervalMinutes < 1)
      ) {
        this.error.syncUsersIntervalMinutes = this.$t("common.required");

        if (isValidationOk) {
          this.focusElement("syncUsersIntervalMinutes");
          isValidationOk = false;
        }
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;

      for (const validationError of validationErrors) {
        const field = validationError.field;

        if (field !== "(root)") {
          // set i18n error message
          this.error[field] = this.$t("settings." + validationError.error);

          if (!focusAlreadySet) {
            this.focusElement(field);
            focusAlreadySet = true;
          }
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.letsEncrypt,
            user_domain: this.userDomain === "-" ? "" : this.userDomain,
            sync_users_enabled: this.syncUsersEnabled,
            sync_users_interval_minutes: Number(this.syncUsersIntervalMinutes),
          },
          extra: {
            title: this.$t("settings.configure_instance", {
              instance: this.instanceName,
            }),
            description: this.$t("common.processing"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
</style>
