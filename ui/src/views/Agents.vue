<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title page-title-with-action">
        <h2>{{ $t("agents.title") }}</h2>
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
    <cv-row v-for="notification in notifications" :key="notification.key">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="notification.title"
          :description="notification.description"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>

    <cv-row v-if="lastAgentToken || lastAgentAction">
      <cv-column>
        <NsInlineNotification
          kind="success"
          :title="$t('agents.agent_token')"
          :description="tokenMessage"
          :showCloseButton="true"
          @close="clearToken"
        />
      </cv-column>
    </cv-row>
    <cv-row v-if="lastAgentToken">
      <cv-column>
        <cv-tile light class="token-tile">
          <div class="key-value-setting">
            <span class="label">{{ $t("agents.agent") }}</span>
            <span class="value">{{
              resourceLabel(lastAgent, ["slug", "display_name", "id"])
            }}</span>
          </div>
          <div class="key-value-setting">
            <span class="label">{{ $t("agents.one_time_token") }}</span>
            <span class="value break-word token-value">{{
              lastAgentToken
            }}</span>
          </div>
          <div class="key-value-setting" v-if="lastStoredTokenFile">
            <span class="label">{{ $t("agents.stored_token_file") }}</span>
            <span class="value break-word">{{ lastStoredTokenFile }}</span>
          </div>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("agents.create_agent") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="createAgent">
            <cv-row>
              <cv-column :md="4" :max="4">
                <cv-text-input
                  :label="$t('agents.slug')"
                  v-model.trim="createForm.slug"
                  :invalid-message="error.slug"
                  :disabled="loading.createAgent"
                  ref="slug"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="5">
                <cv-text-input
                  :label="$t('agents.display_name')"
                  v-model.trim="createForm.display_name"
                  :disabled="loading.createAgent"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="3" class="checkbox-column">
                <cv-checkbox
                  v-model="createForm.store_token"
                  :label="$t('agents.store_token')"
                  :disabled="loading.createAgent"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.createAgent"
              :disabled="loading.createAgent"
              >{{ $t("agents.create_agent") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("agents.rotate_token") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="rotateAgentToken">
            <cv-row>
              <cv-column :md="4" :max="5">
                <NsComboBox
                  v-model="rotateAgentId"
                  :options="agentOptions"
                  :title="$t('agents.agent')"
                  :label="$t('agents.choose_agent')"
                  :invalid-message="error.rotateAgentId"
                  :disabled="loading.rotateAgentToken || !agentOptions.length"
                  auto-highlight
                  ref="rotateAgentId"
                />
              </cv-column>
              <cv-column :md="4" :max="3" class="checkbox-column">
                <cv-checkbox
                  v-model="rotateStoreToken"
                  :label="$t('agents.store_token')"
                  :disabled="loading.rotateAgentToken"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="secondary"
              :icon="Renew20"
              :loading="loading.rotateAgentToken"
              :disabled="loading.rotateAgentToken || !agentOptions.length"
              >{{ $t("agents.rotate_token") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("agents.agents") }}</h4>
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
            v-else-if="!agents.length"
            :title="$t('agents.no_agents')"
          />
          <cv-structured-list v-else>
            <template slot="headings">
              <cv-structured-list-heading>{{
                $t("agents.slug")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("agents.display_name")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("agents.status")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("agents.id")
              }}</cv-structured-list-heading>
              <cv-structured-list-heading>{{
                $t("agents.actions")
              }}</cv-structured-list-heading>
            </template>
            <template slot="items">
              <cv-structured-list-item v-for="agent in agents" :key="agent.id">
                <cv-structured-list-data>{{
                  agent.slug
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  agent.display_name
                }}</cv-structured-list-data>
                <cv-structured-list-data>{{
                  agent.status
                }}</cv-structured-list-data>
                <cv-structured-list-data class="break-word">{{
                  agent.id
                }}</cv-structured-list-data>
                <cv-structured-list-data>
                  <NsButton
                    kind="danger--ghost"
                    size="small"
                    :loading="pendingDisableAgentId === agent.id"
                    :disabled="
                      agent.status === 'disabled' ||
                      pendingDisableAgentId === agent.id
                    "
                    @click="disableAgent(agent)"
                    >{{ $t("agents.disable") }}</NsButton
                  >
                </cv-structured-list-data>
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
  name: "Agents",
  mixins: [
    TaskService,
    QueryParamService,
    IconService,
    UtilService,
    PageTitleService,
    GrantoraAdminMixin,
  ],
  pageTitle() {
    return this.$t("agents.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "agents",
      },
      urlCheckInterval: null,
      overview: this.emptyOverview(),
      createForm: {
        slug: "",
        display_name: "",
        store_token: false,
      },
      rotateAgentId: "",
      rotateStoreToken: false,
      pendingDisableAgentId: "",
      lastAgentAction: "",
      lastAgent: {},
      lastAgentToken: "",
      lastStoredTokenFile: "",
      loading: {
        getAdminOverview: false,
        createAgent: false,
        rotateAgentToken: false,
      },
      error: {
        getAdminOverview: "",
        createAgent: "",
        rotateAgentToken: "",
        disableAgent: "",
        slug: "",
        rotateAgentId: "",
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    agents() {
      return this.overview.resources.agents || [];
    },
    agentOptions() {
      return this.resourceOptions(this.agents, ["slug", "display_name", "id"]);
    },
    notifications() {
      return [
        ["getAdminOverview", "get-admin-overview"],
        ["createAgent", "create-agent"],
        ["rotateAgentToken", "rotate-agent-token"],
        ["disableAgent", "disable-agent"],
      ]
        .filter(([key]) => this.error[key])
        .map(([key, action]) => ({
          key,
          title: this.$t("action." + action),
          description: this.error[key],
        }));
    },
    tokenMessage() {
      if (this.lastAgentToken) {
        return this.$t("agents.one_time_token_ready");
      }
      return this.$t("agents.no_new_token", { action: this.lastAgentAction });
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
        resources: {
          agents: [],
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
    validateCreateAgent() {
      this.error.slug = "";
      if (!this.createForm.slug) {
        this.error.slug = this.$t("common.required");
        this.focusElement("slug");
        return false;
      }
      return true;
    },
    async createAgent() {
      if (!this.validateCreateAgent()) {
        return;
      }
      this.loading.createAgent = true;
      this.error.createAgent = "";

      await this.runGrantoraAction("create-agent", {
        data: {
          slug: this.createForm.slug,
          display_name: this.createForm.display_name || this.createForm.slug,
          store_token: this.createForm.store_token,
        },
        description: this.$t("common.processing"),
        onCompleted: this.createAgentCompleted,
        onAborted: this.createAgentAborted,
        onError: (err) => {
          this.error.createAgent = this.getErrorMessage(err);
          this.loading.createAgent = false;
        },
      });
    },
    createAgentAborted(taskResult) {
      this.error.createAgent = this.taskError(taskResult);
      this.loading.createAgent = false;
    },
    createAgentCompleted(taskContext, taskResult) {
      this.loading.createAgent = false;
      this.recordTokenResult(taskResult.output || {});
      this.createForm.slug = "";
      this.createForm.display_name = "";
      this.createForm.store_token = false;
      this.getAdminOverview();
    },
    validateRotateAgentToken() {
      this.error.rotateAgentId = "";
      if (!this.rotateAgentId) {
        this.error.rotateAgentId = this.$t("common.required");
        this.focusElement("rotateAgentId");
        return false;
      }
      return true;
    },
    async rotateAgentToken() {
      if (!this.validateRotateAgentToken()) {
        return;
      }
      this.loading.rotateAgentToken = true;
      this.error.rotateAgentToken = "";

      await this.runGrantoraAction("rotate-agent-token", {
        data: {
          agent_id: this.rotateAgentId,
          store_token: this.rotateStoreToken,
        },
        description: this.$t("common.processing"),
        onCompleted: this.rotateAgentTokenCompleted,
        onAborted: this.rotateAgentTokenAborted,
        onError: (err) => {
          this.error.rotateAgentToken = this.getErrorMessage(err);
          this.loading.rotateAgentToken = false;
        },
      });
    },
    rotateAgentTokenAborted(taskResult) {
      this.error.rotateAgentToken = this.taskError(taskResult);
      this.loading.rotateAgentToken = false;
    },
    rotateAgentTokenCompleted(taskContext, taskResult) {
      this.loading.rotateAgentToken = false;
      this.recordTokenResult(taskResult.output || {});
      this.rotateStoreToken = false;
      this.getAdminOverview();
    },
    disableAgent(agent) {
      if (
        !window.confirm(
          this.$t("agents.confirm_disable", { agent: agent.slug })
        )
      ) {
        return;
      }
      this.pendingDisableAgentId = agent.id;
      this.error.disableAgent = "";

      this.runGrantoraAction("disable-agent", {
        data: { agent_id: agent.id },
        description: this.$t("common.processing"),
        onCompleted: this.disableAgentCompleted,
        onAborted: this.disableAgentAborted,
        onError: (err) => {
          this.error.disableAgent = this.getErrorMessage(err);
          this.pendingDisableAgentId = "";
        },
      });
    },
    disableAgentAborted(taskResult) {
      this.error.disableAgent = this.taskError(taskResult);
      this.pendingDisableAgentId = "";
    },
    disableAgentCompleted() {
      this.pendingDisableAgentId = "";
      this.getAdminOverview();
    },
    recordTokenResult(output) {
      this.lastAgentAction = output.action || "";
      this.lastAgent = output.agent || {};
      this.lastAgentToken = output.agent_token || "";
      this.lastStoredTokenFile = output.stored_token_file || "";
    },
    clearToken() {
      this.lastAgentAction = "";
      this.lastAgent = {};
      this.lastAgentToken = "";
      this.lastStoredTokenFile = "";
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

.checkbox-column {
  display: flex;
  align-items: flex-end;
  min-height: 4.5rem;
}

.token-tile {
  margin-bottom: $spacing-05;
}

.token-value {
  font-family: monospace;
}

.break-word {
  overflow-wrap: anywhere;
}
</style>
