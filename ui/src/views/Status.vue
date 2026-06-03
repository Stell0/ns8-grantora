<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title page-title-with-action">
        <h2>{{ $t("status.title") }}</h2>
        <NsButton
          kind="secondary"
          :icon="Renew20"
          :loading="loading.getStatus"
          :disabled="loading.getStatus"
          @click="getStatus"
          >{{ $t("common.refresh") }}</NsButton
        >
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getStatus">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-status')"
          :description="error.getStatus"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row v-if="error.syncUsers">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.sync-users')"
          :description="error.syncUsers"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{
            $t("status.public_runtime_url")
          }}</span>
          <cv-link
            v-if="status.public_base_url"
            :href="status.public_base_url"
            target="_blank"
            class="metric-value break-word"
          >
            {{ status.public_base_url }}
          </cv-link>
          <span v-else class="metric-value">-</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{ $t("status.pod") }}</span>
          <span class="metric-value">{{ formatValue(status.pod.state) }}</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{ $t("status.running_version") }}</span>
          <span class="metric-value">{{ runningVersion }}</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{
            $t("status.selected_user_domain")
          }}</span>
          <span class="metric-value">{{
            formatValue(status.selected_user_domain)
          }}</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{ $t("status.metrics") }}</span>
          <span class="metric-value">{{ metricsState }}</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{ $t("status.retention") }}</span>
          <span class="metric-value">{{ retentionWindow }}</span>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("status.runtime_checks") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-skeleton-text
            v-if="loading.getStatus"
            :paragraph="true"
            :line-count="5"
          ></cv-skeleton-text>
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("status.check")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("status.result")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("status.details")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item>
                <cv-structured-list-data>{{
                  $t("status.healthz")
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  checkResult(status.healthz)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  checkDetails(status.healthz)
                }}</cv-structured-list-data>
              </cv-structured-list-item>
              <cv-structured-list-item>
                <cv-structured-list-data>{{
                  $t("status.readyz")
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  checkResult(status.readyz)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  checkDetails(status.readyz)
                }}</cv-structured-list-data>
              </cv-structured-list-item>
              <cv-structured-list-item>
                <cv-structured-list-data>{{
                  $t("status.apisix_sync")
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  checkResult(status.apisix_sync)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  checkDetails(status.apisix_sync)
                }}</cv-structured-list-data>
              </cv-structured-list-item>
              <cv-structured-list-item v-if="status.metrics.enabled">
                <cv-structured-list-data>{{
                  $t("status.metrics")
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  checkResult(status.metrics.probe)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  checkDetails(status.metrics.probe)
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("status.user_sync") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <div v-if="!loading.getStatus" class="sync-grid">
            <div class="key-value-setting">
              <span class="label">{{ $t("status.last_sync") }}</span>
              <span class="value">{{
                formatTimestamp(status.user_sync.last_sync)
              }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.imported") }}</span>
              <span class="value">{{ status.user_sync.imported || 0 }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.disabled") }}</span>
              <span class="value">{{ status.user_sync.disabled || 0 }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.errors") }}</span>
              <span class="value">{{ status.user_sync.errors || 0 }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.last_sync_error") }}</span>
              <span class="value break-word">{{
                formatValue(status.last_sync_error)
              }}</span>
            </div>
            <NsButton
              kind="secondary"
              :icon="Renew20"
              :loading="loading.syncUsers"
              :disabled="loading.syncUsers || !status.sync_users_enabled"
              @click="syncUsers"
              >{{ $t("status.sync_users_now") }}</NsButton
            >
          </div>
          <cv-skeleton-text
            v-else
            :paragraph="true"
            :line-count="4"
          ></cv-skeleton-text>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("status.systemd_units") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-skeleton-text
            v-if="loading.getStatus"
            :paragraph="true"
            :line-count="5"
          ></cv-skeleton-text>
          <NsEmptyState
            v-else-if="!unitRows.length"
            :title="$t('status.no_units')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("status.name")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("status.state")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item
                v-for="unit in unitRows"
                :key="unit.name"
              >
                <cv-structured-list-data>{{
                  unit.name
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  unit.state
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("status.containers") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-skeleton-text
            v-if="loading.getStatus"
            :paragraph="true"
            :line-count="5"
          ></cv-skeleton-text>
          <NsEmptyState
            v-else-if="!containerRows.length"
            :title="$t('status.no_containers')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("status.name")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("status.state")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("status.health")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("status.version")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("status.image")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item
                v-for="container in containerRows"
                :key="container.name"
              >
                <cv-structured-list-data>{{
                  container.name
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  container.state
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  container.health
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(container.version)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  container.image
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("status.operations") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <div v-if="!loading.getStatus" class="sync-grid">
            <div class="key-value-setting">
              <span class="label">{{ $t("status.log_backend") }}</span>
              <span class="value break-word">{{
                formatValue(status.logs.backend)
              }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.structured_logs") }}</span>
              <span class="value">{{ structuredLogsState }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.retention_timer") }}</span>
              <span class="value">{{
                formatValue(status.retention.timer_state)
              }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.retention_last_run") }}</span>
              <span class="value break-word">{{ retentionLastRun }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.metrics_helper") }}</span>
              <span class="value break-word">{{
                formatValue(status.metrics.helper_command)
              }}</span>
            </div>
            <div class="key-value-setting">
              <span class="label">{{ $t("status.retention_helper") }}</span>
              <span class="value break-word">{{
                formatValue(status.retention.helper_command)
              }}</span>
            </div>
          </div>
          <cv-skeleton-text
            v-else
            :paragraph="true"
            :line-count="4"
          ></cv-skeleton-text>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import { mapState } from "vuex";
import {
  QueryParamService,
  TaskService,
  IconService,
  UtilService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";
import GrantoraAdminMixin from "../mixins/GrantoraAdminMixin";

export default {
  name: "Status",
  mixins: [
    TaskService,
    QueryParamService,
    IconService,
    UtilService,
    PageTitleService,
    GrantoraAdminMixin,
  ],
  pageTitle() {
    return this.$t("status.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "status",
      },
      urlCheckInterval: null,
      status: this.emptyStatus(),
      loading: {
        getStatus: false,
        syncUsers: false,
      },
      error: {
        getStatus: "",
        syncUsers: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    runningVersion() {
      return (
        this.status.running_upstream_version ||
        this.status.grantora_version ||
        "-"
      );
    },
    metricsState() {
      return this.status.metrics.enabled
        ? this.$t("common.enabled")
        : this.$t("common.disabled");
    },
    retentionWindow() {
      const retention = this.status.retention || {};
      if (!retention.audit_retention_days && !retention.usage_retention_days) {
        return "-";
      }
      return this.$t("status.retention_window", {
        audit: retention.audit_retention_days || 0,
        usage: retention.usage_retention_days || 0,
      });
    },
    retentionLastRun() {
      const lastRun = (this.status.retention || {}).last_run || {};
      if (!lastRun.ran_at) {
        return "-";
      }
      const mode = lastRun.dry_run
        ? this.$t("status.dry_run")
        : this.$t("status.applied");
      return `${this.formatTimestamp(lastRun.ran_at)} (${mode})`;
    },
    structuredLogsState() {
      return this.status.logs.structured_json
        ? this.$t("common.enabled")
        : this.$t("common.disabled");
    },
    unitRows() {
      return Object.keys(this.status.units || {}).map((name) => ({
        name,
        state: this.status.units[name],
      }));
    },
    containerRows() {
      return Object.keys(this.status.containers || {}).map((name) => ({
        name,
        state: this.status.containers[name].state || "unknown",
        health: this.status.containers[name].health || "unknown",
        version: this.status.containers[name].version || "",
        image: this.status.containers[name].image || "",
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
    this.getStatus();
  },
  methods: {
    emptyStatus() {
      return {
        configured: false,
        public_base_url: "",
        selected_user_domain: "",
        sync_users_enabled: false,
        grantora_version: "",
        pod: {},
        units: {},
        containers: {},
        container_versions: {},
        healthz: {},
        readyz: {},
        api_liveness: {},
        api_readiness: {},
        apisix_sync: {},
        user_sync: {},
        last_sync_error: "",
        bootstrap: {},
        logs: {},
        metrics: {},
        retention: {},
        running_upstream_version: "",
      };
    },
    async getStatus() {
      this.loading.getStatus = true;
      this.error.getStatus = "";
      const taskAction = "get-status";

      await this.runGrantoraAction(taskAction, {
        isNotificationHidden: true,
        onCompleted: this.getStatusCompleted,
        onAborted: this.getStatusAborted,
        onError: (err) => {
          this.error.getStatus = this.getErrorMessage(err);
          this.loading.getStatus = false;
        },
      });
    },
    getStatusAborted() {
      this.error.getStatus = this.$t("error.generic_error");
      this.loading.getStatus = false;
    },
    getStatusCompleted(taskContext, taskResult) {
      this.status = Object.assign(this.emptyStatus(), taskResult.output || {});
      this.loading.getStatus = false;
    },
    async syncUsers() {
      this.loading.syncUsers = true;
      this.error.syncUsers = "";
      const taskAction = "sync-users";

      await this.runGrantoraAction(taskAction, {
        description: this.$t("common.processing"),
        onCompleted: this.syncUsersCompleted,
        onAborted: this.syncUsersAborted,
        onError: (err) => {
          this.error.syncUsers = this.getErrorMessage(err);
          this.loading.syncUsers = false;
        },
      });
    },
    syncUsersAborted() {
      this.error.syncUsers = this.$t("error.generic_error");
      this.loading.syncUsers = false;
    },
    syncUsersCompleted() {
      this.loading.syncUsers = false;
      this.getStatus();
    },
    checkResult(check) {
      if (!check || Object.keys(check).length === 0) {
        return "-";
      }
      return check.ok ? this.$t("common.ok") : this.$t("error.error");
    },
    checkDetails(check) {
      if (!check) {
        return "-";
      }
      if (check.error) {
        return check.error;
      }
      if (check.body && typeof check.body === "object") {
        return JSON.stringify(check.body);
      }
      return this.formatValue(check.body || check.status_code);
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";

.page-title-with-action {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: $spacing-05;
}

.metric-card {
  min-height: 7rem;
}

.metric-label {
  display: block;
  color: $text-02;
  margin-bottom: $spacing-03;
}

.metric-value {
  display: block;
  font-size: 1.15rem;
  line-height: 1.4;
}

.break-word {
  overflow-wrap: anywhere;
}

.sync-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(12rem, 1fr));
  gap: $spacing-05;
  align-items: end;
}
</style>
