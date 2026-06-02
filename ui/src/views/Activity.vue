<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title page-title-with-action">
        <h2>{{ $t("activity.title") }}</h2>
        <NsButton
          kind="secondary"
          :icon="Renew20"
          :loading="loading.getAdminOverview"
          :disabled="loading.getAdminOverview"
          @click="getAdminOverview"
          >{{ $t("common.refresh") }}</NsButton
        >
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getAdminOverview">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-admin-overview')"
          :description="error.getAdminOverview"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("activity.usage_summary") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-skeleton-text
            v-if="loading.getAdminOverview"
            :paragraph="true"
            :line-count="5"
          ></cv-skeleton-text>
          <NsEmptyState
            v-else-if="!usageSummaries.length"
            :title="$t('activity.no_usage_summary')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("activity.agent")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.user")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.capability")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.status")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.events")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.total_units")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item
                v-for="summary in usageSummaries"
                :key="summaryKey(summary)"
              >
                <cv-structured-list-data class="break-word">{{
                  formatValue(summary.agent_id)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(summary.user_id)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(summary.capability_id)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  formatValue(summary.status)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  summary.events || 0
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  summary.total_units || 0
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("activity.audit_events") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <NsEmptyState
            v-if="!auditEvents.length"
            :title="$t('activity.no_audit_events')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("activity.timestamp")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.actor")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.decision")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.outcome")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.capability")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item
                v-for="event in auditEvents"
                :key="event.id"
              >
                <cv-structured-list-data>{{
                  formatTimestamp(event.timestamp)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  formatValue(event.actor_type)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  formatValue(event.decision)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  formatValue(event.outcome)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(event.capability_id)
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("activity.usage_events") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <NsEmptyState
            v-if="!usageEvents.length"
            :title="$t('activity.no_usage_events')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("activity.timestamp")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.agent")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.user")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.capability")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.status")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("activity.units")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item
                v-for="event in usageEvents"
                :key="event.id"
              >
                <cv-structured-list-data>{{
                  formatTimestamp(event.timestamp)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(event.agent_id)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(event.user_id)
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(event.capability_id)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  formatValue(event.status)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  event.units || 0
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
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
  name: "Activity",
  mixins: [
    TaskService,
    QueryParamService,
    IconService,
    UtilService,
    PageTitleService,
    GrantoraAdminMixin,
  ],
  pageTitle() {
    return this.$t("activity.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "activity",
      },
      urlCheckInterval: null,
      overview: {
        audit: [],
        usage: [],
        usage_summaries: [],
      },
      loading: {
        getAdminOverview: false,
      },
      error: {
        getAdminOverview: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    auditEvents() {
      return this.overview.audit || [];
    },
    usageEvents() {
      return this.overview.usage || [];
    },
    usageSummaries() {
      return this.overview.usage_summaries || [];
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
    this.getAdminOverview();
  },
  methods: {
    async getAdminOverview() {
      this.loading.getAdminOverview = true;
      this.error.getAdminOverview = "";
      const taskAction = "get-admin-overview";

      await this.runGrantoraAction(taskAction, {
        data: { limit: 200, events_limit: 50 },
        isNotificationHidden: true,
        onCompleted: this.getAdminOverviewCompleted,
        onAborted: this.getAdminOverviewAborted,
        onError: (err) => {
          this.error.getAdminOverview = this.getErrorMessage(err);
          this.loading.getAdminOverview = false;
        },
      });
    },
    getAdminOverviewAborted(taskResult) {
      this.error.getAdminOverview = this.taskError(taskResult);
      this.loading.getAdminOverview = false;
    },
    getAdminOverviewCompleted(taskContext, taskResult) {
      this.overview = Object.assign(this.overview, taskResult.output || {});
      this.loading.getAdminOverview = false;
    },
    summaryKey(summary) {
      return [
        summary.workspace_id,
        summary.agent_id,
        summary.user_id,
        summary.capability_id,
        summary.status,
      ].join(":");
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

.break-word {
  overflow-wrap: anywhere;
}
</style>
