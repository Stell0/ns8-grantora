<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title page-title-with-action">
        <h2>{{ $t("workspace.title") }}</h2>
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
    <cv-row v-if="error.bootstrapWorkspace">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.bootstrap-workspace')"
          :description="error.bootstrapWorkspace"
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
          <span class="metric-label">{{ $t("workspace.workspace_id") }}</span>
          <span class="metric-value break-word">{{
            formatValue(overview.workspace_id)
          }}</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{ $t("workspace.templates") }}</span>
          <span class="metric-value">{{ templates.length }}</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card">
          <span class="metric-label">{{
            $t("workspace.last_bootstrap_update")
          }}</span>
          <span class="metric-value">{{
            formatTimestamp(overview.bootstrap.updated_at)
          }}</span>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="4">
        <cv-tile light class="metric-card action-card">
          <span class="metric-label">{{ $t("workspace.user_sync") }}</span>
          <NsButton
            kind="secondary"
            :icon="Renew20"
            :loading="loading.syncUsers"
            :disabled="loading.syncUsers"
            @click="syncUsers"
            >{{ $t("workspace.sync_users_now") }}</NsButton
          >
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("workspace.bootstrap") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="bootstrapWorkspace">
            <cv-row>
              <cv-column :md="4" :max="4">
                <cv-text-input
                  :label="$t('workspace.workspace_slug')"
                  v-model.trim="bootstrapForm.workspace_slug"
                  :disabled="loading.bootstrapWorkspace"
                  ref="workspaceSlug"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="5">
                <cv-text-input
                  :label="$t('workspace.workspace_display_name')"
                  v-model.trim="bootstrapForm.workspace_display_name"
                  :disabled="loading.bootstrapWorkspace"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="3">
                <cv-text-input
                  :label="$t('workspace.provider_type')"
                  v-model.trim="bootstrapForm.provider_type"
                  :disabled="loading.bootstrapWorkspace"
                ></cv-text-input>
              </cv-column>
            </cv-row>
            <cv-row>
              <cv-column class="checkbox-column">
                <cv-checkbox
                  v-model="bootstrapForm.side_effect_role_enabled"
                  :label="$t('workspace.side_effect_role_enabled')"
                  :disabled="loading.bootstrapWorkspace"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.bootstrapWorkspace"
              :disabled="loading.bootstrapWorkspace"
              >{{ $t("workspace.bootstrap_action") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("workspace.workspaces") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-skeleton-text
            v-if="loading.getAdminOverview"
            :paragraph="true"
            :line-count="4"
          ></cv-skeleton-text>
          <NsEmptyState
            v-else-if="!workspaces.length"
            :title="$t('workspace.no_workspaces')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("workspace.slug")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.display_name")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.status")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.id")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item
                v-for="workspace in workspaces"
                :key="workspace.id"
              >
                <cv-structured-list-data>{{
                  workspace.slug
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  workspace.display_name
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  workspace.status
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  workspace.id
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("workspace.roles") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <NsEmptyState
            v-if="!roles.length"
            :title="$t('workspace.no_roles')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("workspace.slug")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.permissions")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.status")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item v-for="role in roles" :key="role.id">
                <cv-structured-list-data>{{
                  role.slug
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(role.permission_codes)
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  role.status
                }}</cv-structured-list-data>
              </cv-structured-list-item>
            </template>
          </cv-structured-list>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("workspace.capability_templates") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <NsEmptyState
            v-if="!templates.length"
            :title="$t('workspace.no_templates')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("workspace.id")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.name")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.provider_type")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.risk_class")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("workspace.required_secret_types")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item
                v-for="template in templates"
                :key="template.id"
              >
                <cv-structured-list-data class="break-word">{{
                  template.id
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  template.name
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  template.provider_type
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  template.risk_class
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  formatValue(template.required_secret_types)
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
  name: "Workspace",
  mixins: [
    TaskService,
    QueryParamService,
    IconService,
    UtilService,
    PageTitleService,
    GrantoraAdminMixin,
  ],
  pageTitle() {
    return this.$t("workspace.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "workspace",
      },
      urlCheckInterval: null,
      overview: this.emptyOverview(),
      bootstrapForm: {
        workspace_slug: "default",
        workspace_display_name: "Grantora Default Workspace",
        side_effect_role_enabled: false,
        provider_type: "",
      },
      loading: {
        getAdminOverview: false,
        bootstrapWorkspace: false,
        syncUsers: false,
      },
      error: {
        getAdminOverview: "",
        bootstrapWorkspace: "",
        syncUsers: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    resources() {
      return this.overview.resources || {};
    },
    workspaces() {
      return this.resources.workspaces || [];
    },
    roles() {
      return this.resources.roles || [];
    },
    templates() {
      return this.resources.capability_templates || [];
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
    emptyOverview() {
      return {
        workspace_id: "",
        bootstrap: {},
        resources: {
          workspaces: [],
          roles: [],
          capability_templates: [],
        },
      };
    },
    async getAdminOverview() {
      this.loading.getAdminOverview = true;
      this.error.getAdminOverview = "";
      const taskAction = "get-admin-overview";

      await this.runGrantoraAction(taskAction, {
        data: { limit: 200, events_limit: 25 },
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
      this.overview = Object.assign(
        this.emptyOverview(),
        taskResult.output || {}
      );
      this.loading.getAdminOverview = false;
    },
    async bootstrapWorkspace() {
      this.loading.bootstrapWorkspace = true;
      this.error.bootstrapWorkspace = "";
      const data = {
        workspace_slug: this.bootstrapForm.workspace_slug,
        workspace_display_name: this.bootstrapForm.workspace_display_name,
        side_effect_role_enabled: this.bootstrapForm.side_effect_role_enabled,
      };

      if (this.bootstrapForm.provider_type) {
        data.provider_type = this.bootstrapForm.provider_type;
      }

      await this.runGrantoraAction("bootstrap-workspace", {
        data,
        description: this.$t("common.processing"),
        onCompleted: this.bootstrapWorkspaceCompleted,
        onAborted: this.bootstrapWorkspaceAborted,
        onError: (err) => {
          this.error.bootstrapWorkspace = this.getErrorMessage(err);
          this.loading.bootstrapWorkspace = false;
        },
      });
    },
    bootstrapWorkspaceAborted(taskResult) {
      this.error.bootstrapWorkspace = this.taskError(taskResult);
      this.loading.bootstrapWorkspace = false;
    },
    bootstrapWorkspaceCompleted() {
      this.loading.bootstrapWorkspace = false;
      this.getAdminOverview();
    },
    async syncUsers() {
      this.loading.syncUsers = true;
      this.error.syncUsers = "";

      await this.runGrantoraAction("sync-users", {
        description: this.$t("common.processing"),
        onCompleted: this.syncUsersCompleted,
        onAborted: this.syncUsersAborted,
        onError: (err) => {
          this.error.syncUsers = this.getErrorMessage(err);
          this.loading.syncUsers = false;
        },
      });
    },
    syncUsersAborted(taskResult) {
      this.error.syncUsers = this.taskError(taskResult);
      this.loading.syncUsers = false;
    },
    syncUsersCompleted() {
      this.loading.syncUsers = false;
      this.getAdminOverview();
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

.action-card {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
}

.checkbox-column {
  display: flex;
  align-items: flex-end;
  min-height: 4.5rem;
}

.break-word {
  overflow-wrap: anywhere;
}
</style>
