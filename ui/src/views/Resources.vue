<!--
  Copyright (C) 2023 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title page-title-with-action">
        <h2>{{ $t("resources.title") }}</h2>
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

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("resources.create_application") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="createApplication">
            <cv-row>
              <cv-column :md="4" :max="3">
                <cv-text-input
                  :label="$t('resources.slug')"
                  v-model.trim="applicationForm.slug"
                  :invalid-message="error.applicationSlug"
                  ref="applicationSlug"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="3">
                <cv-text-input
                  :label="$t('resources.provider_type')"
                  v-model.trim="applicationForm.provider_type"
                  :invalid-message="error.applicationProviderType"
                  ref="applicationProviderType"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="3">
                <cv-text-input
                  :label="$t('resources.display_name')"
                  v-model.trim="applicationForm.display_name"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="3">
                <cv-text-input
                  :label="$t('resources.base_url')"
                  v-model.trim="applicationForm.base_url"
                  :invalid-message="error.applicationBaseUrl"
                  ref="applicationBaseUrl"
                ></cv-text-input>
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.createApplication"
              :disabled="loading.createApplication"
              >{{ $t("resources.create_application") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("resources.create_capability") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="createCapability">
            <cv-row>
              <cv-column :md="4" :max="4">
                <NsComboBox
                  v-model="capabilityForm.template_id"
                  :options="templateOptions"
                  :title="$t('resources.template')"
                  :label="$t('resources.choose_template')"
                  :invalid-message="error.templateId"
                  auto-highlight
                  ref="templateId"
                />
              </cv-column>
              <cv-column :md="4" :max="4">
                <NsComboBox
                  v-model="capabilityForm.application_instance_id"
                  :options="applicationOptions"
                  :title="$t('resources.application')"
                  :label="$t('resources.choose_application')"
                  :invalid-message="error.capabilityApplicationId"
                  auto-highlight
                  ref="capabilityApplicationId"
                />
              </cv-column>
              <cv-column :md="4" :max="4">
                <cv-text-input
                  :label="$t('resources.capability_id')"
                  v-model.trim="capabilityForm.id"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="4">
                <cv-text-input
                  :label="$t('resources.name')"
                  v-model.trim="capabilityForm.name"
                ></cv-text-input>
              </cv-column>
              <cv-column :md="4" :max="4">
                <cv-text-input
                  :label="$t('resources.version')"
                  v-model.number="capabilityForm.version"
                ></cv-text-input>
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.createCapability"
              :disabled="
                loading.createCapability ||
                !templateOptions.length ||
                !applicationOptions.length
              "
              >{{ $t("resources.create_capability") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("resources.create_binding") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="createBinding">
            <cv-row>
              <cv-column :md="4" :max="3">
                <NsComboBox
                  v-model="bindingForm.agent_id"
                  :options="agentOptions"
                  :title="$t('resources.agent')"
                  :label="$t('resources.choose_agent')"
                  :invalid-message="error.bindingAgentId"
                  auto-highlight
                  ref="bindingAgentId"
                />
              </cv-column>
              <cv-column :md="4" :max="3">
                <NsComboBox
                  v-model="bindingForm.user_id"
                  :options="userOptions"
                  :title="$t('resources.user')"
                  :label="$t('resources.choose_user')"
                  :invalid-message="error.bindingUserId"
                  auto-highlight
                  ref="bindingUserId"
                />
              </cv-column>
              <cv-column :md="4" :max="3">
                <NsComboBox
                  v-model="bindingForm.capability_id"
                  :options="capabilityOptions"
                  :title="$t('resources.capability')"
                  :label="$t('resources.choose_capability')"
                  :invalid-message="error.bindingCapabilityId"
                  auto-highlight
                  ref="bindingCapabilityId"
                />
              </cv-column>
              <cv-column :md="4" :max="3">
                <NsComboBox
                  v-model="bindingForm.role_id"
                  :options="roleOptions"
                  :title="$t('resources.role')"
                  :label="$t('resources.choose_role')"
                  :invalid-message="error.bindingRoleId"
                  auto-highlight
                  ref="bindingRoleId"
                />
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.createBinding"
              :disabled="loading.createBinding"
              >{{ $t("resources.create_binding") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("resources.secrets") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column :md="4" :max="6">
        <cv-tile light>
          <h5>{{ $t("resources.create_secret") }}</h5>
          <cv-form @submit.prevent="createSecret">
            <NsComboBox
              v-model="secretForm.application_instance_id"
              :options="applicationOptions"
              :title="$t('resources.application')"
              :label="$t('resources.choose_application')"
              :invalid-message="error.secretApplicationId"
              auto-highlight
              ref="secretApplicationId"
            />
            <NsComboBox
              v-model="secretForm.owner_type"
              :options="ownerTypeOptions"
              :title="$t('resources.owner_type')"
              :label="$t('resources.choose_owner_type')"
              auto-highlight
            />
            <NsComboBox
              v-model="secretForm.owner_id"
              :options="ownerOptions"
              :title="$t('resources.owner')"
              :label="$t('resources.choose_owner')"
              :invalid-message="error.secretOwnerId"
              auto-highlight
              ref="secretOwnerId"
            />
            <NsComboBox
              v-model="secretForm.secret_type"
              :options="secretTypeOptions"
              :title="$t('resources.secret_type')"
              :label="$t('resources.choose_secret_type')"
              auto-highlight
            />
            <cv-text-input
              :label="$t('resources.secret_value')"
              v-model.trim="secretForm.secret_value"
              type="password"
            ></cv-text-input>
            <cv-text-input
              :label="$t('resources.external_reference')"
              v-model.trim="secretForm.external_reference"
            ></cv-text-input>
            <div class="field-error" v-if="error.secretSource">
              {{ error.secretSource }}
            </div>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.createSecret"
              :disabled="loading.createSecret"
              >{{ $t("resources.create_secret") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
      <cv-column :md="4" :max="6">
        <cv-tile light>
          <h5>{{ $t("resources.rotate_secret") }}</h5>
          <cv-form @submit.prevent="rotateSecret">
            <NsComboBox
              v-model="rotateSecretForm.secret_id"
              :options="secretOptions"
              :title="$t('resources.secret')"
              :label="$t('resources.choose_secret')"
              :invalid-message="error.rotateSecretId"
              auto-highlight
              ref="rotateSecretId"
            />
            <NsComboBox
              v-model="rotateSecretForm.secret_type"
              :options="secretTypeOptionsWithEmpty"
              :title="$t('resources.secret_type')"
              :label="$t('resources.keep_secret_type')"
              auto-highlight
            />
            <cv-text-input
              :label="$t('resources.secret_value')"
              v-model.trim="rotateSecretForm.secret_value"
              type="password"
            ></cv-text-input>
            <cv-text-input
              :label="$t('resources.external_reference')"
              v-model.trim="rotateSecretForm.external_reference"
            ></cv-text-input>
            <div class="field-error" v-if="error.rotateSecretSource">
              {{ error.rotateSecretSource }}
            </div>
            <NsButton
              kind="secondary"
              :icon="Renew20"
              :loading="loading.rotateSecret"
              :disabled="loading.rotateSecret || !secretOptions.length"
              >{{ $t("resources.rotate_secret") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>

    <cv-row>
      <cv-column class="page-subtitle">
        <h4>{{ $t("resources.current_resources") }}</h4>
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-skeleton-text
            v-if="loading.getAdminOverview"
            :paragraph="true"
            :line-count="6"
          ></cv-skeleton-text>
          <div v-else class="resource-sections">
            <section>
              <h5>{{ $t("resources.applications") }}</h5>
              <NsEmptyState
                v-if="!applications.length"
                :title="$t('resources.no_applications')"
              />
              <cv-structured-list v-else>
                <template slot="headings"
                  ><cv-structured-list-heading>{{
                    $t("resources.slug")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.provider_type")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.base_url")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.status")
                  }}</cv-structured-list-heading></template
                >
                <template slot="items"
                  ><cv-structured-list-item
                    v-for="application in applications"
                    :key="application.id"
                    ><cv-structured-list-data>{{
                      application.slug
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      application.provider_type
                    }}</cv-structured-list-data
                    ><cv-structured-list-data class="break-word">{{
                      application.base_url
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      application.status
                    }}</cv-structured-list-data></cv-structured-list-item
                  ></template
                >
              </cv-structured-list>
            </section>
            <section>
              <h5>{{ $t("resources.capabilities") }}</h5>
              <NsEmptyState
                v-if="!capabilities.length"
                :title="$t('resources.no_capabilities')"
              />
              <cv-structured-list v-else>
                <template slot="headings"
                  ><cv-structured-list-heading>{{
                    $t("resources.id")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.name")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.risk_class")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.status")
                  }}</cv-structured-list-heading></template
                >
                <template slot="items"
                  ><cv-structured-list-item
                    v-for="capability in capabilities"
                    :key="capability.id"
                    ><cv-structured-list-data class="break-word">{{
                      capability.id
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      capability.name
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      capability.risk_class
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      capability.status
                    }}</cv-structured-list-data></cv-structured-list-item
                  ></template
                >
              </cv-structured-list>
            </section>
            <section>
              <h5>{{ $t("resources.bindings") }}</h5>
              <NsEmptyState
                v-if="!bindings.length"
                :title="$t('resources.no_bindings')"
              />
              <cv-structured-list v-else>
                <template slot="headings"
                  ><cv-structured-list-heading>{{
                    $t("resources.agent")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.user")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.capability")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.role")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.status")
                  }}</cv-structured-list-heading></template
                >
                <template slot="items"
                  ><cv-structured-list-item
                    v-for="binding in bindings"
                    :key="binding.id"
                    ><cv-structured-list-data class="break-word">{{
                      binding.agent_id
                    }}</cv-structured-list-data
                    ><cv-structured-list-data class="break-word">{{
                      binding.user_id
                    }}</cv-structured-list-data
                    ><cv-structured-list-data class="break-word">{{
                      binding.capability_id
                    }}</cv-structured-list-data
                    ><cv-structured-list-data class="break-word">{{
                      binding.role_id
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      binding.status
                    }}</cv-structured-list-data></cv-structured-list-item
                  ></template
                >
              </cv-structured-list>
            </section>
            <section>
              <h5>{{ $t("resources.secrets") }}</h5>
              <NsEmptyState
                v-if="!secrets.length"
                :title="$t('resources.no_secrets')"
              />
              <cv-structured-list v-else>
                <template slot="headings"
                  ><cv-structured-list-heading>{{
                    $t("resources.secret_type")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.owner_type")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.owner")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.status")
                  }}</cv-structured-list-heading
                  ><cv-structured-list-heading>{{
                    $t("resources.id")
                  }}</cv-structured-list-heading></template
                >
                <template slot="items"
                  ><cv-structured-list-item
                    v-for="secret in secrets"
                    :key="secret.id"
                    ><cv-structured-list-data>{{
                      secret.secret_type
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      secret.owner_type
                    }}</cv-structured-list-data
                    ><cv-structured-list-data class="break-word">{{
                      secret.owner_id
                    }}</cv-structured-list-data
                    ><cv-structured-list-data>{{
                      secret.status
                    }}</cv-structured-list-data
                    ><cv-structured-list-data class="break-word">{{
                      secret.id
                    }}</cv-structured-list-data></cv-structured-list-item
                  ></template
                >
              </cv-structured-list>
            </section>
          </div>
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
  name: "Resources",
  mixins: [
    TaskService,
    QueryParamService,
    IconService,
    UtilService,
    PageTitleService,
    GrantoraAdminMixin,
  ],
  pageTitle() {
    return this.$t("resources.title") + " - " + this.appName;
  },
  data() {
    return {
      q: { page: "resources" },
      urlCheckInterval: null,
      overview: this.emptyOverview(),
      applicationForm: {
        slug: "",
        display_name: "",
        provider_type: "",
        base_url: "",
      },
      capabilityForm: {
        template_id: "",
        application_instance_id: "",
        id: "",
        name: "",
        version: 1,
      },
      bindingForm: {
        agent_id: "",
        user_id: "",
        capability_id: "",
        role_id: "",
      },
      secretForm: {
        application_instance_id: "",
        owner_type: "workspace",
        owner_id: "",
        secret_type: "api_key",
        secret_value: "",
        external_reference: "",
      },
      rotateSecretForm: {
        secret_id: "",
        secret_type: "",
        secret_value: "",
        external_reference: "",
      },
      loading: {
        getAdminOverview: false,
        createApplication: false,
        createCapability: false,
        createBinding: false,
        createSecret: false,
        rotateSecret: false,
      },
      error: this.emptyErrors(),
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
    applications() {
      return this.resources.applications || [];
    },
    templates() {
      return this.resources.capability_templates || [];
    },
    capabilities() {
      return this.resources.capabilities || [];
    },
    agents() {
      return this.resources.agents || [];
    },
    users() {
      return this.resources.users || [];
    },
    roles() {
      return this.resources.roles || [];
    },
    bindings() {
      return this.resources.bindings || [];
    },
    secrets() {
      return this.resources.secrets || [];
    },
    applicationOptions() {
      return this.resourceOptions(this.applications, [
        "slug",
        "display_name",
        "id",
      ]);
    },
    templateOptions() {
      return this.resourceOptions(this.templates, ["id", "name"]);
    },
    capabilityOptions() {
      return this.resourceOptions(this.capabilities, ["id", "name"]);
    },
    agentOptions() {
      return this.resourceOptions(this.agents, ["slug", "display_name", "id"]);
    },
    userOptions() {
      return this.resourceOptions(this.users, [
        "external_id",
        "display_name",
        "id",
      ]);
    },
    roleOptions() {
      return this.resourceOptions(this.roles, ["slug", "display_name", "id"]);
    },
    secretOptions() {
      return this.resourceOptions(this.secrets, ["secret_type", "id"]);
    },
    ownerOptions() {
      if (this.secretForm.owner_type === "user") {
        return this.userOptions;
      }
      if (this.secretForm.owner_type === "agent") {
        return this.agentOptions;
      }
      return this.resourceOptions(this.workspaces, [
        "slug",
        "display_name",
        "id",
      ]);
    },
    ownerTypeOptions() {
      return ["workspace", "user", "agent"].map((value) => ({
        name: value,
        label: this.$t("resources.owner_type_" + value),
        value,
      }));
    },
    secretTypeOptions() {
      return [
        "api_key",
        "bearer_token",
        "basic_auth",
        "oauth_refresh_token",
        "session_cookie",
      ].map((value) => ({
        name: value,
        label: this.$t("resources.secret_type_" + value),
        value,
      }));
    },
    secretTypeOptionsWithEmpty() {
      return [
        {
          name: "keep",
          label: this.$t("resources.keep_secret_type"),
          value: "",
        },
      ].concat(this.secretTypeOptions);
    },
    notifications() {
      return [
        ["getAdminOverview", "get-admin-overview"],
        ["createApplication", "create-application"],
        ["createCapability", "create-capability-from-template"],
        ["createBinding", "create-binding"],
        ["createSecret", "create-secret"],
        ["rotateSecret", "rotate-secret"],
      ]
        .filter(([key]) => this.error[key])
        .map(([key, action]) => ({
          key,
          title: this.$t("action." + action),
          description: this.error[key],
        }));
    },
  },
  watch: {
    "secretForm.owner_type"() {
      this.secretForm.owner_id = "";
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
          workspaces: [],
          applications: [],
          capability_templates: [],
          capabilities: [],
          agents: [],
          users: [],
          roles: [],
          bindings: [],
          secrets: [],
        },
      };
    },
    emptyErrors() {
      return {
        getAdminOverview: "",
        createApplication: "",
        createCapability: "",
        createBinding: "",
        createSecret: "",
        rotateSecret: "",
        applicationSlug: "",
        applicationProviderType: "",
        applicationBaseUrl: "",
        templateId: "",
        capabilityApplicationId: "",
        bindingAgentId: "",
        bindingUserId: "",
        bindingCapabilityId: "",
        bindingRoleId: "",
        secretApplicationId: "",
        secretOwnerId: "",
        secretSource: "",
        rotateSecretId: "",
        rotateSecretSource: "",
      };
    },
    async getAdminOverview() {
      this.loading.getAdminOverview = true;
      this.error.getAdminOverview = "";
      await this.runGrantoraAction("get-admin-overview", {
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
    requireField(errorField, ref, value) {
      this.error[errorField] = "";
      if (!value) {
        this.error[errorField] = this.$t("common.required");
        this.focusElement(ref);
        return false;
      }
      return true;
    },
    validateApplicationBaseUrl() {
      this.error.applicationBaseUrl = "";
      if (!this.applicationForm.base_url) {
        return true;
      }
      try {
        const parsed = new URL(this.applicationForm.base_url);
        if (!["http:", "https:"].includes(parsed.protocol) || !parsed.host) {
          throw new Error("invalid application base URL");
        }
      } catch (error) {
        this.error.applicationBaseUrl = this.$t("resources.invalid_base_url");
        this.focusElement("applicationBaseUrl");
        return false;
      }
      return true;
    },
    async createApplication() {
      if (
        !this.requireField(
          "applicationSlug",
          "applicationSlug",
          this.applicationForm.slug
        ) ||
        !this.requireField(
          "applicationProviderType",
          "applicationProviderType",
          this.applicationForm.provider_type
        ) ||
        !this.validateApplicationBaseUrl()
      ) {
        return;
      }
      const data = {
        slug: this.applicationForm.slug,
        provider_type: this.applicationForm.provider_type,
        display_name:
          this.applicationForm.display_name || this.applicationForm.slug,
      };
      if (this.applicationForm.base_url) {
        data.base_url = this.applicationForm.base_url;
      }
      await this.runWriteAction(
        "create-application",
        "createApplication",
        data,
        () => {
          this.applicationForm = {
            slug: "",
            display_name: "",
            provider_type: "",
            base_url: "",
          };
        }
      );
    },
    async createCapability() {
      if (
        !this.requireField(
          "templateId",
          "templateId",
          this.capabilityForm.template_id
        ) ||
        !this.requireField(
          "capabilityApplicationId",
          "capabilityApplicationId",
          this.capabilityForm.application_instance_id
        )
      ) {
        return;
      }
      const data = {
        template_id: this.capabilityForm.template_id,
        application_instance_id: this.capabilityForm.application_instance_id,
      };
      for (const key of ["id", "name"]) {
        if (this.capabilityForm[key]) {
          data[key] = this.capabilityForm[key];
        }
      }
      if (this.capabilityForm.version) {
        data.version = Number(this.capabilityForm.version);
      }
      await this.runWriteAction(
        "create-capability-from-template",
        "createCapability",
        data,
        () => {
          this.capabilityForm = {
            template_id: "",
            application_instance_id: "",
            id: "",
            name: "",
            version: 1,
          };
        }
      );
    },
    async createBinding() {
      if (
        !this.requireField(
          "bindingAgentId",
          "bindingAgentId",
          this.bindingForm.agent_id
        ) ||
        !this.requireField(
          "bindingUserId",
          "bindingUserId",
          this.bindingForm.user_id
        ) ||
        !this.requireField(
          "bindingCapabilityId",
          "bindingCapabilityId",
          this.bindingForm.capability_id
        ) ||
        !this.requireField(
          "bindingRoleId",
          "bindingRoleId",
          this.bindingForm.role_id
        )
      ) {
        return;
      }
      await this.runWriteAction(
        "create-binding",
        "createBinding",
        Object.assign({}, this.bindingForm),
        () => {
          this.bindingForm = {
            agent_id: "",
            user_id: "",
            capability_id: "",
            role_id: "",
          };
        }
      );
    },
    async createSecret() {
      if (
        !this.requireField(
          "secretApplicationId",
          "secretApplicationId",
          this.secretForm.application_instance_id
        ) ||
        !this.requireField(
          "secretOwnerId",
          "secretOwnerId",
          this.secretForm.owner_id
        )
      ) {
        return;
      }
      const source = this.secretSource(this.secretForm, "secretSource");
      if (!source) {
        return;
      }
      const data = {
        application_instance_id: this.secretForm.application_instance_id,
        owner_type: this.secretForm.owner_type,
        owner_id: this.secretForm.owner_id,
        secret_type: this.secretForm.secret_type,
      };
      Object.assign(data, source);
      await this.runWriteAction("create-secret", "createSecret", data, () => {
        this.secretForm.secret_value = "";
        this.secretForm.external_reference = "";
      });
    },
    async rotateSecret() {
      if (
        !this.requireField(
          "rotateSecretId",
          "rotateSecretId",
          this.rotateSecretForm.secret_id
        )
      ) {
        return;
      }
      const source = this.secretSource(
        this.rotateSecretForm,
        "rotateSecretSource"
      );
      if (!source) {
        return;
      }
      const data = { secret_id: this.rotateSecretForm.secret_id };
      if (this.rotateSecretForm.secret_type) {
        data.secret_type = this.rotateSecretForm.secret_type;
      }
      Object.assign(data, source);
      await this.runWriteAction("rotate-secret", "rotateSecret", data, () => {
        this.rotateSecretForm.secret_value = "";
        this.rotateSecretForm.external_reference = "";
      });
    },
    secretSource(form, errorField) {
      this.error[errorField] = "";
      if (form.secret_value && form.external_reference) {
        this.error[errorField] = this.$t("resources.one_secret_source");
        return null;
      }
      if (form.secret_value) {
        return { secret_value: form.secret_value };
      }
      if (form.external_reference) {
        return { external_reference: form.external_reference };
      }
      this.error[errorField] = this.$t("resources.one_secret_source");
      return null;
    },
    async runWriteAction(action, loadingKey, data, onSuccess) {
      this.loading[loadingKey] = true;
      this.error[loadingKey] = "";
      await this.runGrantoraAction(action, {
        data,
        description: this.$t("common.processing"),
        onCompleted: () => {
          this.loading[loadingKey] = false;
          if (onSuccess) {
            onSuccess();
          }
          this.getAdminOverview();
        },
        onAborted: (taskResult) => {
          this.error[loadingKey] = this.taskError(taskResult);
          this.loading[loadingKey] = false;
        },
        onError: (err) => {
          this.error[loadingKey] = this.getErrorMessage(err);
          this.loading[loadingKey] = false;
        },
      });
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

.resource-sections section {
  margin-bottom: $spacing-07;
}

.field-error {
  color: $support-01;
  margin-bottom: $spacing-05;
}

.break-word {
  overflow-wrap: anywhere;
}
</style>
