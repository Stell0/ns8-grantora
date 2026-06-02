import to from "await-to-js";

export default {
  methods: {
    async runGrantoraAction(taskAction, options = {}) {
      const eventId = this.getUuid();
      const extra = {
        title: options.title || this.$t("action." + taskAction),
        eventId,
      };

      if (options.description) {
        extra.description = options.description;
      }
      if (options.isNotificationHidden) {
        extra.isNotificationHidden = true;
      }

      if (options.onAborted) {
        this.core.$root.$once(
          `${taskAction}-aborted-${eventId}`,
          options.onAborted
        );
      }
      if (options.onValidationFailed) {
        this.core.$root.$once(
          `${taskAction}-validation-failed-${eventId}`,
          options.onValidationFailed
        );
      }
      if (options.onCompleted) {
        this.core.$root.$once(
          `${taskAction}-completed-${eventId}`,
          options.onCompleted
        );
      }

      const task = {
        action: taskAction,
        extra,
      };

      if (Object.prototype.hasOwnProperty.call(options, "data")) {
        task.data = options.data;
      }

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, task)
      );
      const err = res[0];

      if (err) {
        if (options.onError) {
          options.onError(err);
        }
        return false;
      }
      return true;
    },
    asArray(value) {
      if (Array.isArray(value)) {
        return value;
      }
      if (value && typeof value === "object") {
        return Object.values(value);
      }
      return [];
    },
    formatTimestamp(timestamp) {
      if (!timestamp) {
        return "-";
      }
      const numeric = Number(timestamp);
      const date = Number.isFinite(numeric)
        ? new Date(numeric < 1000000000000 ? numeric * 1000 : numeric)
        : new Date(timestamp);

      if (Number.isNaN(date.getTime())) {
        return "-";
      }
      return date.toLocaleString();
    },
    formatValue(value) {
      if (value === undefined || value === null || value === "") {
        return "-";
      }
      if (Array.isArray(value)) {
        return value.length ? value.join(", ") : "-";
      }
      if (typeof value === "boolean") {
        return value ? this.$t("common.enabled") : this.$t("common.disabled");
      }
      return String(value);
    },
    resourceLabel(resource, fields) {
      for (const field of fields) {
        if (resource && resource[field]) {
          return resource[field];
        }
      }
      return resource && resource.id ? resource.id : "-";
    },
    resourceOptions(resources, fields) {
      return this.asArray(resources).map((resource) => ({
        name: resource.id,
        label: this.resourceLabel(resource, fields),
        value: resource.id,
      }));
    },
    taskError(taskResult, fallbackKey = "error.generic_error") {
      if (taskResult && taskResult.error) {
        return taskResult.error;
      }
      return this.$t(fallbackKey);
    },
  },
};
