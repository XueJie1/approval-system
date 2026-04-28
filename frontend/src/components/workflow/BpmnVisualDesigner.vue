<template>
  <div class="bpmn-visual-designer" :class="{ 'is-fullscreen': fullscreen }">
    <div class="designer-toolbar">
      <el-button type="primary" :disabled="disabled || !modelReady" @click="emitSave">保存</el-button>
      <el-button-group>
        <el-button :disabled="disabled || !modelReady || zoomLevel <= 0.2" @click="zoomOut">缩小</el-button>
        <el-button :disabled="disabled || !modelReady || zoomLevel >= 4" @click="zoomIn">放大</el-button>
      </el-button-group>
      <el-button-group>
        <el-button :disabled="disabled || !modelReady || !canUndo" @click="undo">撤销</el-button>
        <el-button :disabled="disabled || !modelReady || !canRedo" @click="redo">重做</el-button>
      </el-button-group>
      <span class="zoom-text">{{ Math.round(zoomLevel * 100) }}%</span>
      <el-tag v-if="selectedGatewayElement" size="small" type="info">
        已选中节点：{{ gatewayForm.name || gatewayForm.id }}（{{ selectedElementTypeLabel }}）
      </el-tag>
      <el-tag v-if="isUserTaskSelected && selectedApprovalStrategyLabel" size="small" type="warning">
        审批策略：{{ selectedApprovalStrategyLabel }}
      </el-tag>
    </div>

    <div class="designer-body" :class="{ 'is-panel-hidden': !propertiesPanelVisible }">
      <div ref="canvasRef" class="designer-canvas"></div>
      <el-button
        v-if="!propertiesPanelVisible"
        class="panel-toggle-fab"
        circle
        type="primary"
        @click="togglePropertiesPanel"
      >
        <el-icon><Menu /></el-icon>
      </el-button>

      <aside v-if="propertiesPanelVisible" class="gateway-panel">
        <div class="gateway-panel__head">
          <div class="gateway-panel__title">节点属性</div>
          <div class="panel-head-actions">
            <el-tag size="small" type="success">可编辑全部节点</el-tag>
            <el-button link type="primary" @click="togglePropertiesPanel">隐藏</el-button>
          </div>
        </div>

        <el-empty
          v-if="!selectedGatewayElement"
          description="点击画布中的节点后，在此处编辑属性"
          :image-size="120"
        />

        <template v-else>
          <el-alert v-if="gatewayReadonly" type="info" :closable="false" show-icon title="当前为只读模式" class="gateway-alert" />

          <el-tabs v-model="gatewayPanelTab" class="gateway-tabs">
            <el-tab-pane label="常规" name="general">
              <el-form label-position="top" class="gateway-form" @submit.prevent>
                <el-form-item label="ID">
                  <el-input v-model="gatewayForm.id" :disabled="gatewayReadonly" maxlength="120" />
                </el-form-item>
                <el-form-item label="名称">
                  <el-input v-model="gatewayForm.name" :disabled="gatewayReadonly" maxlength="120" />
                </el-form-item>
                <div class="gateway-actions">
                  <el-button type="primary" :disabled="gatewayReadonly" @click="applyGatewayBasics">应用节点信息</el-button>
                </div>
              </el-form>

              <template v-if="isUserTaskSelected">
                <div class="gateway-section-title">审批策略</div>
                <el-form label-position="top" class="gateway-form" @submit.prevent>
                  <el-form-item label="策略类型">
                    <el-select
                      v-model="approvalStrategyForm.strategy"
                      :disabled="gatewayReadonly"
                      style="width: 100%"
                    >
                      <el-option
                        v-for="item in approvalStrategyOptions"
                        :key="item.value"
                        :label="item.label"
                        :value="item.value"
                      />
                    </el-select>
                  </el-form-item>
                  <el-alert
                    v-if="approvalStrategyForm.strategy === 'CUSTOM'"
                    type="warning"
                    :closable="false"
                    show-icon
                    title="当前节点为自定义审批配置，应用策略将按标准模板重写该节点审批规则。"
                  />
                  <div class="gateway-actions">
                    <el-button
                      type="primary"
                      :disabled="gatewayReadonly || approvalStrategyForm.strategy === 'CUSTOM'"
                      @click="applyApprovalStrategy"
                    >
                      应用审批策略
                    </el-button>
                  </div>
                </el-form>
              </template>

              <template v-if="isExclusiveGatewaySelected">
                <div class="gateway-section-title">分支条件（纯文本表达式）</div>
                <el-empty v-if="!gatewayConditions.length" description="当前网关没有出线" :image-size="80" />
                <div v-else class="condition-list">
                  <div v-for="item in gatewayConditions" :key="item.id" class="condition-item">
                    <div class="condition-item__meta">
                      <strong>{{ item.id }}</strong>
                      <span v-if="item.targetName">→ {{ item.targetName }}</span>
                    </div>
                    <el-input
                      v-model="item.expression"
                      :disabled="gatewayReadonly"
                      type="textarea"
                      :rows="2"
                      placeholder="例如 ${amount > 1000}"
                    />
                    <el-radio v-model="gatewayDefaultFlowId" :disabled="gatewayReadonly" :label="item.id">设为默认分支</el-radio>
                  </div>
                  <div class="gateway-actions">
                    <el-button type="primary" :disabled="gatewayReadonly" @click="applyGatewayConditions">应用分支条件</el-button>
                  </div>
                </div>
              </template>
            </el-tab-pane>

            <el-tab-pane label="执行监听器" name="listeners">
              <div class="table-toolbar">
                <el-button type="primary" :disabled="gatewayReadonly" @click="openListenerDialog(null, -1)">+ 添加监听器</el-button>
              </div>
              <el-table :data="gatewayListeners" border size="small" max-height="250">
                <el-table-column type="index" label="序号" width="60" />
                <el-table-column prop="event" label="事件类型" width="90" />
                <el-table-column label="监听器类型" min-width="120">
                  <template #default="{ row }">{{ listenerTypeLabel(row.listenerType) }}</template>
                </el-table-column>
                <el-table-column label="值" min-width="150" show-overflow-tooltip>
                  <template #default="{ row }">{{ row.displayValue || '-' }}</template>
                </el-table-column>
                <el-table-column label="操作" width="120">
                  <template #default="{ row, $index }">
                    <el-button link :disabled="gatewayReadonly" @click="openListenerDialog(row, $index)">编辑</el-button>
                    <el-button link type="danger" :disabled="gatewayReadonly" @click="removeListener($index)">删除</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </el-tab-pane>

            <el-tab-pane label="扩展属性" name="properties">
              <div class="table-toolbar">
                <el-button type="primary" :disabled="gatewayReadonly" @click="openPropertyDialog(null, -1)">+ 添加属性</el-button>
              </div>
              <el-table :data="gatewayProperties" border size="small" max-height="250">
                <el-table-column type="index" label="序号" width="60" />
                <el-table-column prop="id" label="ID" min-width="120" show-overflow-tooltip />
                <el-table-column prop="name" label="名称" min-width="120" show-overflow-tooltip />
                <el-table-column prop="value" label="值" min-width="140" show-overflow-tooltip />
                <el-table-column label="操作" width="120">
                  <template #default="{ row, $index }">
                    <el-button link :disabled="gatewayReadonly" @click="openPropertyDialog(row, $index)">编辑</el-button>
                    <el-button link type="danger" :disabled="gatewayReadonly" @click="removeProperty($index)">删除</el-button>
                  </template>
                </el-table-column>
              </el-table>
            </el-tab-pane>

            <el-tab-pane label="其他" name="other">
              <el-form label-position="top" @submit.prevent>
                <el-form-item label="元素文档（备注）">
                  <el-input
                    v-model="gatewayForm.documentation"
                    :disabled="gatewayReadonly"
                    type="textarea"
                    :rows="5"
                    maxlength="2000"
                    show-word-limit
                  />
                </el-form-item>
                <div class="gateway-actions">
                  <el-button type="primary" :disabled="gatewayReadonly" @click="applyGatewayDocumentation">应用备注</el-button>
                </div>
              </el-form>
            </el-tab-pane>
          </el-tabs>
        </template>
      </aside>
    </div>

    <el-dialog v-model="listenerDialogVisible" title="执行监听器" width="640px" destroy-on-close>
      <el-form ref="listenerFormRef" :model="listenerForm" label-position="top" @submit.prevent>
        <el-form-item label="事件类型" prop="event" :rules="[{ required: true, message: '请选择事件类型', trigger: 'change' }]">
          <el-select v-model="listenerForm.event" placeholder="请选择" style="width: 100%">
            <el-option v-for="item in listenerEventOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>

        <el-form-item label="监听器类型" prop="listenerType" :rules="[{ required: true, message: '请选择监听器类型', trigger: 'change' }]">
          <el-select v-model="listenerForm.listenerType" placeholder="请选择" style="width: 100%" @change="onListenerTypeChange">
            <el-option v-for="item in listenerTypeOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>

        <template v-if="listenerForm.listenerType !== 'scriptListener'">
          <el-form-item
            :label="listenerExpressionLabel"
            prop="expressionValue"
            :rules="[{ required: true, message: '请填写内容', trigger: 'blur' }]"
          >
            <el-input v-model="listenerForm.expressionValue" :placeholder="listenerExpressionPlaceholder" />
          </el-form-item>
        </template>

        <template v-else>
          <el-form-item label="脚本格式" prop="scriptFormat" :rules="[{ required: true, message: '请输入脚本格式', trigger: 'blur' }]">
            <el-input v-model="listenerForm.scriptFormat" placeholder="例如 groovy / javascript" />
          </el-form-item>
          <el-form-item label="脚本类型" prop="scriptType" :rules="[{ required: true, message: '请选择脚本类型', trigger: 'change' }]">
            <el-select v-model="listenerForm.scriptType" placeholder="请选择" style="width: 100%">
              <el-option v-for="item in listenerScriptTypeOptions" :key="item.value" :label="item.label" :value="item.value" />
            </el-select>
          </el-form-item>
          <el-form-item
            v-if="listenerForm.scriptType === 'inlineScript'"
            label="脚本内容"
            prop="scriptValue"
            :rules="[{ required: true, message: '请输入脚本内容', trigger: 'blur' }]"
          >
            <el-input v-model="listenerForm.scriptValue" type="textarea" :rows="3" />
          </el-form-item>
          <el-form-item
            v-else
            label="脚本资源"
            prop="scriptResource"
            :rules="[{ required: true, message: '请输入脚本资源', trigger: 'blur' }]"
          >
            <el-input v-model="listenerForm.scriptResource" placeholder="例如 classpath:script.groovy" />
          </el-form-item>
        </template>
      </el-form>

      <el-divider />

      <div class="field-toolbar">
        <span class="field-toolbar__title">注入字段</span>
        <el-button type="primary" @click="openListenerFieldDialog(null, -1)">添加字段</el-button>
      </div>
      <el-table :data="listenerForm.fields" border size="small" max-height="220">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="name" label="字段名称" min-width="120" />
        <el-table-column label="字段类型" width="100">
          <template #default="{ row }">{{ row.fieldType === 'expression' ? '表达式' : '字符串' }}</template>
        </el-table-column>
        <el-table-column label="字段值/表达式" min-width="150" show-overflow-tooltip>
          <template #default="{ row }">{{ row.fieldType === 'expression' ? row.expression : row.string }}</template>
        </el-table-column>
        <el-table-column label="操作" width="120">
          <template #default="{ row, $index }">
            <el-button link @click="openListenerFieldDialog(row, $index)">编辑</el-button>
            <el-button link type="danger" @click="removeListenerField($index)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <template #footer>
        <el-button @click="closeListenerDialog">取消</el-button>
        <el-button type="primary" @click="saveListenerConfig">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="listenerFieldDialogVisible" title="注入字段" width="540px" destroy-on-close>
      <el-form ref="listenerFieldFormRef" :model="listenerFieldForm" label-position="top" @submit.prevent>
        <el-form-item label="字段名称" prop="name" :rules="[{ required: true, message: '请输入字段名称', trigger: 'blur' }]">
          <el-input v-model="listenerFieldForm.name" />
        </el-form-item>
        <el-form-item label="字段类型" prop="fieldType" :rules="[{ required: true, message: '请选择字段类型', trigger: 'change' }]">
          <el-select v-model="listenerFieldForm.fieldType" style="width: 100%">
            <el-option v-for="item in fieldTypeOptions" :key="item.value" :label="item.label" :value="item.value" />
          </el-select>
        </el-form-item>
        <el-form-item
          v-if="listenerFieldForm.fieldType === 'string'"
          label="字段值"
          prop="string"
          :rules="[{ required: true, message: '请输入字段值', trigger: 'blur' }]"
        >
          <el-input v-model="listenerFieldForm.string" />
        </el-form-item>
        <el-form-item
          v-else
          label="字段表达式"
          prop="expression"
          :rules="[{ required: true, message: '请输入字段表达式', trigger: 'blur' }]"
        >
          <el-input v-model="listenerFieldForm.expression" placeholder="例如 ${deptId}" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="closeListenerFieldDialog">取消</el-button>
        <el-button type="primary" @click="saveListenerField">保存</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="propertyDialogVisible" title="扩展属性" width="520px" destroy-on-close>
      <el-form ref="propertyFormRef" :model="propertyForm" label-position="top" @submit.prevent>
        <el-form-item label="属性 ID">
          <el-input v-model="propertyForm.id" maxlength="120" placeholder="可为空" />
        </el-form-item>
        <el-form-item label="属性名称" prop="name" :rules="[{ required: true, message: '请输入属性名称', trigger: 'blur' }]">
          <el-input v-model="propertyForm.name" maxlength="120" />
        </el-form-item>
        <el-form-item label="属性值" prop="value" :rules="[{ required: true, message: '请输入属性值', trigger: 'blur' }]">
          <el-input v-model="propertyForm.value" maxlength="255" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="closePropertyDialog">取消</el-button>
        <el-button type="primary" @click="saveProperty">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import BpmnModeler from "bpmn-js/lib/Modeler";
import { ElMessage, ElMessageBox } from "element-plus";
import { Menu } from "@element-plus/icons-vue";
import { markRaw } from "vue";
import flowableModdle from "./bpmn/flowable-moddle.json";

const BPMN_NS = "http://www.omg.org/spec/BPMN/20100524/MODEL";
const BPMNDI_NS = "http://www.omg.org/spec/BPMN/20100524/DI";
const DC_NS = "http://www.omg.org/spec/DD/20100524/DC";
const DI_NS = "http://www.omg.org/spec/DD/20100524/DI";
const XMLNS_NS = "http://www.w3.org/2000/xmlns/";

const LISTENER_EVENT_OPTIONS = [
  { label: "start", value: "start" },
  { label: "end", value: "end" }
];

const LISTENER_TYPE_OPTIONS = [
  { label: "Java 类", value: "classListener" },
  { label: "表达式", value: "expressionListener" },
  { label: "代理表达式", value: "delegateExpressionListener" },
  { label: "脚本", value: "scriptListener" }
];

const LISTENER_SCRIPT_TYPE_OPTIONS = [
  { label: "内联脚本", value: "inlineScript" },
  { label: "外部脚本", value: "externalScript" }
];

const FIELD_TYPE_OPTIONS = [
  { label: "字符串", value: "string" },
  { label: "表达式", value: "expression" }
];

const APPROVAL_STRATEGY_OPTIONS = [
  { label: "Single（单人审批）", value: "SINGLE" },
  { label: "Or-Sign（一票通过）", value: "OR_SIGN" },
  { label: "Countersign（会签）", value: "COUNTERSIGN" },
  { label: "自定义（仅识别，不可直接应用）", value: "CUSTOM" }
];

const OR_SIGN_COMPLETION_CONDITION = "${approveCount >= 1 || rejectCount == nrOfInstances}";
const COUNTERSIGN_COMPLETION_CONDITION = "${countersignMode == 'ALL' ? (rejectCount == 0 && nrOfCompletedInstances == nrOfInstances) : (approveCount >= requiredApprove || rejectCount > (nrOfInstances - requiredApprove))}";

const DEFAULT_XML = (processId = "Process_1", processName = "流程") => `<?xml version="1.0" encoding="UTF-8"?>
<bpmn:definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
  xmlns:bpmndi="http://www.omg.org/spec/BPMN/20100524/DI"
  xmlns:dc="http://www.omg.org/spec/DD/20100524/DC"
  xmlns:di="http://www.omg.org/spec/DD/20100524/DI"
  xmlns:flowable="http://flowable.org/bpmn"
  id="Definitions_1"
  targetNamespace="http://www.flowable.org/processdef">
  <bpmn:process id="${processId}" name="${processName}" isExecutable="true">
    <bpmn:startEvent id="StartEvent_1" name="开始">
      <bpmn:outgoing>Flow_1</bpmn:outgoing>
    </bpmn:startEvent>
    <bpmn:userTask id="Activity_Approve" name="审批">
      <bpmn:incoming>Flow_1</bpmn:incoming>
      <bpmn:outgoing>Flow_2</bpmn:outgoing>
    </bpmn:userTask>
    <bpmn:endEvent id="EndEvent_1" name="结束">
      <bpmn:incoming>Flow_2</bpmn:incoming>
    </bpmn:endEvent>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="StartEvent_1" targetRef="Activity_Approve" />
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Activity_Approve" targetRef="EndEvent_1" />
  </bpmn:process>
  <bpmndi:BPMNDiagram id="BPMNDiagram_1">
    <bpmndi:BPMNPlane id="BPMNPlane_1" bpmnElement="${processId}">
      <bpmndi:BPMNShape id="StartEvent_1_di" bpmnElement="StartEvent_1">
        <dc:Bounds x="150" y="120" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="Activity_Approve_di" bpmnElement="Activity_Approve">
        <dc:Bounds x="250" y="98" width="100" height="80" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNShape id="EndEvent_1_di" bpmnElement="EndEvent_1">
        <dc:Bounds x="430" y="120" width="36" height="36" />
      </bpmndi:BPMNShape>
      <bpmndi:BPMNEdge id="Flow_1_di" bpmnElement="Flow_1">
        <di:waypoint x="186" y="138" />
        <di:waypoint x="250" y="138" />
      </bpmndi:BPMNEdge>
      <bpmndi:BPMNEdge id="Flow_2_di" bpmnElement="Flow_2">
        <di:waypoint x="350" y="138" />
        <di:waypoint x="430" y="138" />
      </bpmndi:BPMNEdge>
    </bpmndi:BPMNPlane>
  </bpmndi:BPMNDiagram>
</bpmn:definitions>`;

export default {
  name: "BpmnVisualDesigner",
  components: {
    Menu
  },
  props: {
    xml: {
      type: String,
      default: ""
    },
    processId: {
      type: String,
      default: ""
    },
    processName: {
      type: String,
      default: ""
    },
    disabled: {
      type: Boolean,
      default: false
    },
    canEdit: {
      type: Boolean,
      default: true
    },
    fullscreen: {
      type: Boolean,
      default: false
    },
    reloadToken: {
      type: Number,
      default: 0
    }
  },
  emits: ["save", "xml-change", "import-error"],
  data() {
    return {
      modeler: null,
      currentXml: "",
      canUndo: false,
      canRedo: false,
      zoomLevel: 1,
      suppressXmlEvent: false,
      modelReady: false,
      resizeObserver: null,
      propertiesPanelVisible: true,
      selectedGatewayElement: null,
      gatewayPanelTab: "general",
      gatewayForm: {
        id: "",
        name: "",
        documentation: ""
      },
      gatewayConditions: [],
      gatewayDefaultFlowId: "",
      gatewayListeners: [],
      gatewayProperties: [],
      listenerDialogVisible: false,
      listenerEditingIndex: -1,
      listenerForm: {
        event: "start",
        listenerType: "expressionListener",
        expressionValue: "",
        scriptType: "inlineScript",
        scriptFormat: "",
        scriptValue: "",
        scriptResource: "",
        fields: []
      },
      listenerFieldDialogVisible: false,
      listenerFieldEditingIndex: -1,
      listenerFieldForm: {
        name: "",
        fieldType: "string",
        string: "",
        expression: ""
      },
      propertyDialogVisible: false,
      propertyEditingIndex: -1,
      propertyForm: {
        id: "",
        name: "",
        value: ""
      },
      approvalStrategyForm: {
        strategy: "SINGLE"
      },
      listenerEventOptions: LISTENER_EVENT_OPTIONS,
      listenerTypeOptions: LISTENER_TYPE_OPTIONS,
      listenerScriptTypeOptions: LISTENER_SCRIPT_TYPE_OPTIONS,
      fieldTypeOptions: FIELD_TYPE_OPTIONS,
      approvalStrategyOptions: APPROVAL_STRATEGY_OPTIONS
    };
  },
  computed: {
    gatewayReadonly() {
      return this.disabled || !this.canEdit;
    },
    selectedElementType() {
      return this.selectedGatewayElement?.businessObject?.$type || "";
    },
    selectedElementTypeLabel() {
      return this.formatElementTypeLabel(this.selectedElementType);
    },
    isExclusiveGatewaySelected() {
      return this.selectedElementType === "bpmn:ExclusiveGateway";
    },
    isUserTaskSelected() {
      return this.selectedElementType === "bpmn:UserTask";
    },
    selectedApprovalStrategyLabel() {
      if (!this.isUserTaskSelected) {
        return "";
      }
      const strategy = this.detectUserTaskApprovalStrategy(this.selectedGatewayElement?.businessObject);
      return this.approvalStrategyOptions.find((item) => item.value === strategy)?.label || "自定义";
    },
    listenerExpressionLabel() {
      if (this.listenerForm.listenerType === "classListener") {
        return "Java 类";
      }
      if (this.listenerForm.listenerType === "delegateExpressionListener") {
        return "代理表达式";
      }
      return "表达式";
    },
    listenerExpressionPlaceholder() {
      if (this.listenerForm.listenerType === "classListener") {
        return "例如 com.example.WorkflowListener";
      }
      if (this.listenerForm.listenerType === "delegateExpressionListener") {
        return "例如 ${listenerBean}";
      }
      return "例如 ${amount > 1000}";
    }
  },
  mounted() {
    this.initModeler();
    this.observeCanvasResize();
    this.importXml(this.xml);
  },
  beforeUnmount() {
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }
    if (this.modeler) {
      this.modeler.destroy();
      this.modeler = null;
    }
  },
  watch: {
    xml(value) {
      if (value === this.currentXml) {
        return;
      }
      this.importXml(value);
    },
    reloadToken() {
      this.importXml(this.xml);
    },
    fullscreen(value) {
      if (!value) {
        return;
      }
      this.$nextTick(() => {
        this.fitToViewport();
      });
    }
  },
  methods: {
    togglePropertiesPanel() {
      this.propertiesPanelVisible = !this.propertiesPanelVisible;
    },
    isEditableFlowNode(element) {
      const businessObject = element?.businessObject;
      if (!businessObject || typeof businessObject.$instanceOf !== "function") {
        return false;
      }
      return businessObject.$instanceOf("bpmn:FlowNode");
    },
    formatElementTypeLabel(type) {
      if (!type) {
        return "";
      }
      const mapping = {
        "bpmn:StartEvent": "开始事件",
        "bpmn:EndEvent": "结束事件",
        "bpmn:UserTask": "用户任务",
        "bpmn:ServiceTask": "服务任务",
        "bpmn:ScriptTask": "脚本任务",
        "bpmn:Task": "任务",
        "bpmn:ExclusiveGateway": "排他网关",
        "bpmn:ParallelGateway": "并行网关",
        "bpmn:InclusiveGateway": "包容网关",
        "bpmn:EventBasedGateway": "事件网关",
        "bpmn:SubProcess": "子流程",
        "bpmn:CallActivity": "调用活动"
      };
      return mapping[type] || type.replace("bpmn:", "");
    },
    initModeler() {
      if (this.modeler) {
        return;
      }
      this.modeler = new BpmnModeler({
        container: this.$refs.canvasRef,
        keyboard: this.disabled ? undefined : { bindTo: document },
        moddleExtensions: {
          flowable: flowableModdle
        }
      });
      this.modelReady = true;

      const eventBus = this.modeler.get("eventBus");
      eventBus.on("commandStack.changed", async () => {
        const commandStack = this.modeler.get("commandStack");
        this.canUndo = commandStack.canUndo();
        this.canRedo = commandStack.canRedo();
        if (this.suppressXmlEvent) {
          return;
        }
        if (this.selectedGatewayElement) {
          this.syncGatewayPanelFromSelection();
        }
        try {
          const { xml } = await this.modeler.saveXML({ format: true });
          this.currentXml = xml;
          this.$emit("xml-change", xml);
        } catch (error) {
          this.$emit("import-error", this.toImportError("BPMN XML 读取失败", error));
        }
      });

      eventBus.on("canvas.viewbox.changed", ({ viewbox }) => {
        this.zoomLevel = Math.floor(viewbox.scale * 100) / 100;
      });

      eventBus.on("selection.changed", ({ newSelection }) => {
        this.handleSelectionChanged((newSelection && newSelection[0]) || null);
      });
    },
    async importXml(xml) {
      if (!this.modeler) {
        return;
      }
      const processId = this.processId || "Process_1";
      const processName = this.processName || "流程";
      const sourceXml = (xml || "").trim() || DEFAULT_XML(processId, processName);
      const normalizedXml = this.normalizeXmlForImport(sourceXml);
      const candidates = normalizedXml !== sourceXml ? [normalizedXml, sourceXml] : [sourceXml];
      this.suppressXmlEvent = true;
      try {
        let imported = false;
        let lastError = null;
        for (const candidateXml of candidates) {
          try {
            await this.importAndSync(candidateXml);
            imported = true;
            break;
          } catch (error) {
            lastError = error;
          }
        }
        if (!imported) {
          this.$emit("import-error", this.toImportError("BPMN XML 导入失败", lastError));
        }
      } catch (error) {
        this.$emit("import-error", this.toImportError("BPMN XML 导入失败", error));
      } finally {
        this.suppressXmlEvent = false;
      }
    },
    async emitSave() {
      if (!this.modeler) {
        return;
      }
      try {
        const { xml } = await this.modeler.saveXML({ format: true });
        this.currentXml = xml;
        this.$emit("save", xml);
      } catch (error) {
        this.$emit("import-error", this.toImportError("BPMN XML 保存失败", error));
      }
    },
    async importAndSync(xml) {
      await this.modeler.importXML(xml);
      const { xml: importedXml } = await this.modeler.saveXML({ format: true });
      this.currentXml = importedXml;
      this.$emit("xml-change", importedXml);
      this.canUndo = false;
      this.canRedo = false;
      this.clearGatewaySelection();
      await this.waitForLayout();
      this.fitToViewport();
    },
    async waitForLayout() {
      await this.$nextTick();
      await new Promise((resolve) => {
        if (typeof requestAnimationFrame === "function") {
          requestAnimationFrame(() => resolve());
          return;
        }
        setTimeout(resolve, 0);
      });
    },
    fitToViewport() {
      if (!this.modeler) {
        return;
      }
      const canvas = this.modeler.get("canvas");
      canvas.resized();
      const rect = this.$refs.canvasRef?.getBoundingClientRect?.();
      if (!rect || rect.width <= 0 || rect.height <= 0) {
        return;
      }
      try {
        canvas.zoom("fit-viewport", "auto");
      } catch (_error) {
        try {
          canvas.zoom(1);
        } catch {
          return;
        }
      }
      const viewbox = canvas.viewbox();
      if (viewbox && Number.isFinite(viewbox.scale)) {
        this.zoomLevel = Math.floor(viewbox.scale * 100) / 100;
        return;
      }
      this.zoomLevel = 1;
    },
    observeCanvasResize() {
      if (typeof ResizeObserver !== "function" || !this.$refs.canvasRef) {
        return;
      }
      this.resizeObserver = new ResizeObserver(() => {
        if (!this.modeler) {
          return;
        }
        this.modeler.get("canvas").resized();
      });
      this.resizeObserver.observe(this.$refs.canvasRef);
    },
    handleSelectionChanged(element) {
      if (!this.isEditableFlowNode(element)) {
        this.clearGatewaySelection();
        return;
      }
      this.selectedGatewayElement = markRaw(element);
      this.syncGatewayPanelFromSelection();
    },
    clearGatewaySelection() {
      this.selectedGatewayElement = null;
      this.gatewayPanelTab = "general";
      this.gatewayForm = {
        id: "",
        name: "",
        documentation: ""
      };
      this.gatewayConditions = [];
      this.gatewayDefaultFlowId = "";
      this.gatewayListeners = [];
      this.gatewayProperties = [];
      this.approvalStrategyForm = {
        strategy: "SINGLE"
      };
    },
    syncGatewayPanelFromSelection() {
      const businessObject = this.selectedGatewayElement?.businessObject;
      if (!businessObject) {
        this.clearGatewaySelection();
        return;
      }
      this.gatewayForm = {
        id: businessObject.id || "",
        name: businessObject.name || "",
        documentation: this.extractDocumentation(businessObject)
      };
      this.gatewayConditions = this.isExclusiveGatewaySelected ? this.extractGatewayConditions() : [];
      this.gatewayDefaultFlowId = this.isExclusiveGatewaySelected ? (businessObject.default?.id || "") : "";
      this.gatewayListeners = this.extractExecutionListeners(businessObject);
      this.gatewayProperties = this.extractExtensionProperties(businessObject);
      this.approvalStrategyForm = {
        strategy: this.detectUserTaskApprovalStrategy(businessObject)
      };
    },
    normalizeExpressionText(value) {
      return String(value || "")
        .replace(/\s+/g, " ")
        .replace(/\s*([(){}?:=!<>+\-*/&|])\s*/g, "$1")
        .trim();
    },
    detectUserTaskApprovalStrategy(businessObject) {
      if (!businessObject || businessObject.$type !== "bpmn:UserTask") {
        return "SINGLE";
      }
      const loop = businessObject.loopCharacteristics;
      if (!loop || loop.$type !== "bpmn:MultiInstanceLoopCharacteristics") {
        return "SINGLE";
      }
      const completionBody = this.normalizeExpressionText(loop.completionCondition?.body || "");
      const normalizedOrSign = this.normalizeExpressionText(OR_SIGN_COMPLETION_CONDITION);
      if (completionBody === normalizedOrSign
        || (completionBody.includes("approveCount>=1") && completionBody.includes("rejectCount==nrOfInstances"))) {
        return "OR_SIGN";
      }
      if (completionBody.includes("countersignMode=='ALL'")
        || completionBody.includes("requiredApprove")
        || completionBody.includes("nrOfCompletedInstances==nrOfInstances")) {
        return "COUNTERSIGN";
      }
      return "CUSTOM";
    },
    buildTaskListenerByStrategy(strategy) {
      const moddle = this.modeler.get("moddle");
      if (strategy === "SINGLE") {
        return moddle.create("flowable:TaskListener", {
          event: "complete",
          delegateExpression: "${singleApprovalTaskListener}"
        });
      }
      return moddle.create("flowable:TaskListener", {
        event: "complete",
        delegateExpression: "${countersignTaskListener}"
      });
    },
    buildLoopCharacteristicsByStrategy(strategy) {
      const moddle = this.modeler.get("moddle");
      if (strategy === "SINGLE") {
        return undefined;
      }
      const completionConditionBody = strategy === "OR_SIGN"
        ? OR_SIGN_COMPLETION_CONDITION
        : COUNTERSIGN_COMPLETION_CONDITION;
      return moddle.create("bpmn:MultiInstanceLoopCharacteristics", {
        isSequential: false,
        collection: "countersignUsers",
        elementVariable: "countersignUser",
        completionCondition: moddle.create("bpmn:FormalExpression", { body: completionConditionBody })
      });
    },
    buildAssigneeByStrategy(strategy) {
      return strategy === "SINGLE" ? "${approverId}" : "${countersignUser}";
    },
    applyApprovalStrategy() {
      if (!this.selectedGatewayElement || this.gatewayReadonly || !this.isUserTaskSelected) {
        return;
      }
      const strategy = this.approvalStrategyForm.strategy;
      if (strategy === "CUSTOM") {
        ElMessage.warning("自定义策略无法直接应用，请先选择标准策略");
        return;
      }
      try {
        const businessObject = this.selectedGatewayElement.businessObject;
        const extensionValues = businessObject.extensionElements?.values || [];
        const unmanagedValues = extensionValues.filter(
          (item) => !(item.$type === "flowable:TaskListener" && String(item.event || "").toLowerCase() === "complete")
        );
        const taskListener = this.buildTaskListenerByStrategy(strategy);
        unmanagedValues.push(taskListener);
        const moddle = this.modeler.get("moddle");
        const extensionElements = moddle.create("bpmn:ExtensionElements", { values: unmanagedValues });
        const loopCharacteristics = this.buildLoopCharacteristicsByStrategy(strategy);
        this.modeler.get("modeling").updateProperties(this.selectedGatewayElement, {
          assignee: this.buildAssigneeByStrategy(strategy),
          loopCharacteristics,
          extensionElements
        });
        ElMessage.success("审批策略已更新");
      } catch (error) {
        ElMessage.error(this.toImportError("应用审批策略失败", error).details);
      }
    },
    extractDocumentation(businessObject) {
      const doc = Array.isArray(businessObject.documentation) && businessObject.documentation.length
        ? businessObject.documentation[0]
        : null;
      return doc?.text || "";
    },
    extractGatewayConditions() {
      if (!this.selectedGatewayElement || !this.isExclusiveGatewaySelected) {
        return [];
      }
      const outgoing = Array.isArray(this.selectedGatewayElement.outgoing) ? this.selectedGatewayElement.outgoing : [];
      return outgoing
        .map((connection) => {
          const flow = connection.businessObject;
          const conditionExpression = flow?.conditionExpression?.body || "";
          return {
            id: flow?.id || "",
            name: flow?.name || "",
            targetName: flow?.targetRef?.name || flow?.targetRef?.id || "",
            expression: conditionExpression
          };
        })
        .filter((item) => Boolean(item.id));
    },
    detectListenerType(listener) {
      if (listener.script) {
        return "scriptListener";
      }
      if (listener.delegateExpression) {
        return "delegateExpressionListener";
      }
      if (listener.expression) {
        return "expressionListener";
      }
      return "classListener";
    },
    mapListenerField(field) {
      const isExpression = Boolean(field.expression);
      return {
        name: field.name || "",
        fieldType: isExpression ? "expression" : "string",
        string: field.stringValue || field.string || "",
        expression: field.expression || ""
      };
    },
    extractExecutionListeners(businessObject) {
      const extensionValues = businessObject.extensionElements?.values || [];
      const listeners = extensionValues.filter((item) => item.$type === "flowable:ExecutionListener");
      return listeners.map((listener) => {
        const listenerType = this.detectListenerType(listener);
        const script = listener.script || null;
        const isExternalScript = Boolean(script?.resource);
        const expressionValue = listenerType === "classListener"
          ? (listener.class || "")
          : listenerType === "delegateExpressionListener"
            ? (listener.delegateExpression || "")
            : listenerType === "expressionListener"
              ? (listener.expression || "")
              : "";

        const displayValue = listenerType === "scriptListener"
          ? (script?.value || script?.resource || "")
          : expressionValue;

        return {
          event: listener.event || "start",
          listenerType,
          expressionValue,
          scriptType: isExternalScript ? "externalScript" : "inlineScript",
          scriptFormat: script?.scriptFormat || "",
          scriptValue: script?.value || "",
          scriptResource: script?.resource || "",
          fields: (listener.fields || []).map((field) => this.mapListenerField(field)),
          displayValue
        };
      });
    },
    extractExtensionProperties(businessObject) {
      const extensionValues = businessObject.extensionElements?.values || [];
      const propertiesContainer = extensionValues.find((item) => item.$type === "flowable:Properties");
      if (!propertiesContainer || !Array.isArray(propertiesContainer.values)) {
        return [];
      }
      return propertiesContainer.values.map((item) => ({
        id: item.id || "",
        name: item.name || "",
        value: item.value || ""
      }));
    },
    applyGatewayBasics() {
      if (!this.selectedGatewayElement || this.gatewayReadonly) {
        return;
      }
      const nextId = this.gatewayForm.id.trim();
      if (!nextId) {
        ElMessage.warning("节点 ID 不能为空");
        return;
      }
      try {
        this.modeler.get("modeling").updateProperties(this.selectedGatewayElement, {
          id: nextId,
          di: { id: `${nextId}_di` },
          name: this.gatewayForm.name.trim() || null
        });
      } catch (error) {
        ElMessage.error(this.toImportError("应用节点基础信息失败", error).details);
      }
    },
    applyGatewayConditions() {
      if (!this.selectedGatewayElement || this.gatewayReadonly) {
        return;
      }
      if (!this.isExclusiveGatewaySelected) {
        ElMessage.warning("仅排他网关支持分支条件");
        return;
      }
      try {
        const modeling = this.modeler.get("modeling");
        const moddle = this.modeler.get("moddle");
        const elementRegistry = this.modeler.get("elementRegistry");

        for (const item of this.gatewayConditions) {
          const flowElement = elementRegistry.get(item.id);
          if (!flowElement) {
            continue;
          }
          const expression = item.expression?.trim() || "";
          const conditionExpression = expression
            ? moddle.create("bpmn:FormalExpression", { body: expression })
            : null;
          modeling.updateProperties(flowElement, {
            name: item.name?.trim() || undefined,
            conditionExpression
          });
        }

        const defaultFlow = this.gatewayDefaultFlowId
          ? elementRegistry.get(this.gatewayDefaultFlowId)?.businessObject
          : undefined;

        modeling.updateProperties(this.selectedGatewayElement, {
          default: defaultFlow
        });

        ElMessage.success("分支条件已更新");
      } catch (error) {
        ElMessage.error(this.toImportError("应用分支条件失败", error).details);
      }
    },
    applyGatewayDocumentation() {
      if (!this.selectedGatewayElement || this.gatewayReadonly) {
        return;
      }
      try {
        const moddle = this.modeler.get("moddle");
        const text = this.gatewayForm.documentation.trim();
        const documentation = text
          ? [moddle.create("bpmn:Documentation", { text })]
          : [];
        this.modeler.get("modeling").updateProperties(this.selectedGatewayElement, {
          documentation
        });
        ElMessage.success("节点备注已更新");
      } catch (error) {
        ElMessage.error(this.toImportError("应用节点备注失败", error).details);
      }
    },
    listenerTypeLabel(type) {
      return this.listenerTypeOptions.find((item) => item.value === type)?.label || type;
    },
    openListenerDialog(listener, index) {
      if (!listener) {
        this.listenerEditingIndex = -1;
        this.listenerForm = {
          event: "start",
          listenerType: "expressionListener",
          expressionValue: "",
          scriptType: "inlineScript",
          scriptFormat: "",
          scriptValue: "",
          scriptResource: "",
          fields: []
        };
      } else {
        this.listenerEditingIndex = index;
        this.listenerForm = {
          event: listener.event || "start",
          listenerType: listener.listenerType || "expressionListener",
          expressionValue: listener.expressionValue || "",
          scriptType: listener.scriptType || "inlineScript",
          scriptFormat: listener.scriptFormat || "",
          scriptValue: listener.scriptValue || "",
          scriptResource: listener.scriptResource || "",
          fields: (listener.fields || []).map((item) => ({ ...item }))
        };
      }
      this.listenerDialogVisible = true;
      this.$nextTick(() => {
        this.$refs.listenerFormRef?.clearValidate();
      });
    },
    closeListenerDialog() {
      this.listenerDialogVisible = false;
      this.listenerEditingIndex = -1;
    },
    onListenerTypeChange() {
      this.listenerForm.expressionValue = "";
      this.listenerForm.scriptFormat = "";
      this.listenerForm.scriptValue = "";
      this.listenerForm.scriptResource = "";
      this.listenerForm.scriptType = "inlineScript";
    },
    async saveListenerConfig() {
      if (this.gatewayReadonly) {
        return;
      }
      try {
        await this.$refs.listenerFormRef?.validate();
      } catch {
        return;
      }

      const nextListener = {
        event: this.listenerForm.event,
        listenerType: this.listenerForm.listenerType,
        expressionValue: this.listenerForm.expressionValue?.trim() || "",
        scriptType: this.listenerForm.scriptType,
        scriptFormat: this.listenerForm.scriptFormat?.trim() || "",
        scriptValue: this.listenerForm.scriptValue || "",
        scriptResource: this.listenerForm.scriptResource?.trim() || "",
        fields: (this.listenerForm.fields || []).map((field) => ({
          name: field.name?.trim() || "",
          fieldType: field.fieldType,
          string: field.string || "",
          expression: field.expression || ""
        }))
      };

      const listeners = this.gatewayListeners.map((item) => ({ ...item, fields: (item.fields || []).map((field) => ({ ...field })) }));
      if (this.listenerEditingIndex === -1) {
        listeners.push(nextListener);
      } else {
        listeners.splice(this.listenerEditingIndex, 1, nextListener);
      }

      this.updateGatewayExtensions({ listeners, properties: this.gatewayProperties });
      this.closeListenerDialog();
    },
    async removeListener(index) {
      if (this.gatewayReadonly) {
        return;
      }
      try {
        await ElMessageBox.confirm("确认删除该监听器吗？", "提示", { type: "warning" });
      } catch {
        return;
      }
      const listeners = this.gatewayListeners.slice();
      listeners.splice(index, 1);
      this.updateGatewayExtensions({ listeners, properties: this.gatewayProperties });
    },
    openListenerFieldDialog(field, index) {
      if (!field) {
        this.listenerFieldEditingIndex = -1;
        this.listenerFieldForm = {
          name: "",
          fieldType: "string",
          string: "",
          expression: ""
        };
      } else {
        this.listenerFieldEditingIndex = index;
        this.listenerFieldForm = {
          name: field.name || "",
          fieldType: field.fieldType || "string",
          string: field.string || "",
          expression: field.expression || ""
        };
      }
      this.listenerFieldDialogVisible = true;
      this.$nextTick(() => {
        this.$refs.listenerFieldFormRef?.clearValidate();
      });
    },
    closeListenerFieldDialog() {
      this.listenerFieldDialogVisible = false;
      this.listenerFieldEditingIndex = -1;
    },
    async saveListenerField() {
      try {
        await this.$refs.listenerFieldFormRef?.validate();
      } catch {
        return;
      }
      const nextField = {
        name: this.listenerFieldForm.name?.trim() || "",
        fieldType: this.listenerFieldForm.fieldType,
        string: this.listenerFieldForm.string || "",
        expression: this.listenerFieldForm.expression || ""
      };
      const fields = (this.listenerForm.fields || []).slice();
      if (this.listenerFieldEditingIndex === -1) {
        fields.push(nextField);
      } else {
        fields.splice(this.listenerFieldEditingIndex, 1, nextField);
      }
      this.listenerForm = {
        ...this.listenerForm,
        fields
      };
      this.closeListenerFieldDialog();
    },
    removeListenerField(index) {
      const fields = (this.listenerForm.fields || []).slice();
      fields.splice(index, 1);
      this.listenerForm = {
        ...this.listenerForm,
        fields
      };
    },
    openPropertyDialog(property, index) {
      if (!property) {
        this.propertyEditingIndex = -1;
        this.propertyForm = {
          id: "",
          name: "",
          value: ""
        };
      } else {
        this.propertyEditingIndex = index;
        this.propertyForm = {
          id: property.id || "",
          name: property.name || "",
          value: property.value || ""
        };
      }
      this.propertyDialogVisible = true;
      this.$nextTick(() => {
        this.$refs.propertyFormRef?.clearValidate();
      });
    },
    closePropertyDialog() {
      this.propertyDialogVisible = false;
      this.propertyEditingIndex = -1;
    },
    async saveProperty() {
      if (this.gatewayReadonly) {
        return;
      }
      try {
        await this.$refs.propertyFormRef?.validate();
      } catch {
        return;
      }
      const property = {
        id: this.propertyForm.id?.trim() || "",
        name: this.propertyForm.name?.trim() || "",
        value: this.propertyForm.value?.trim() || ""
      };
      const properties = this.gatewayProperties.slice();
      if (this.propertyEditingIndex === -1) {
        properties.push(property);
      } else {
        properties.splice(this.propertyEditingIndex, 1, property);
      }
      this.updateGatewayExtensions({ listeners: this.gatewayListeners, properties });
      this.closePropertyDialog();
    },
    async removeProperty(index) {
      if (this.gatewayReadonly) {
        return;
      }
      try {
        await ElMessageBox.confirm("确认删除该扩展属性吗？", "提示", { type: "warning" });
      } catch {
        return;
      }
      const properties = this.gatewayProperties.slice();
      properties.splice(index, 1);
      this.updateGatewayExtensions({ listeners: this.gatewayListeners, properties });
    },
    createFieldObject(field) {
      const moddle = this.modeler.get("moddle");
      if (field.fieldType === "expression") {
        return moddle.create("flowable:Field", {
          name: field.name,
          expression: field.expression
        });
      }
      return moddle.create("flowable:Field", {
        name: field.name,
        stringValue: field.string
      });
    },
    createScriptObject(listener) {
      const moddle = this.modeler.get("moddle");
      return moddle.create("flowable:Script", {
        scriptFormat: listener.scriptFormat,
        resource: listener.scriptType === "externalScript" ? listener.scriptResource : undefined,
        value: listener.scriptType === "inlineScript" ? listener.scriptValue : undefined
      });
    },
    createExecutionListenerObject(listener) {
      const moddle = this.modeler.get("moddle");
      const payload = {
        event: listener.event,
        fields: (listener.fields || []).map((field) => this.createFieldObject(field))
      };
      if (listener.listenerType === "classListener") {
        payload.class = listener.expressionValue;
      } else if (listener.listenerType === "delegateExpressionListener") {
        payload.delegateExpression = listener.expressionValue;
      } else if (listener.listenerType === "expressionListener") {
        payload.expression = listener.expressionValue;
      } else {
        payload.script = this.createScriptObject(listener);
      }
      return moddle.create("flowable:ExecutionListener", payload);
    },
    createPropertyObject(property) {
      const moddle = this.modeler.get("moddle");
      return moddle.create("flowable:Property", {
        id: property.id || undefined,
        name: property.name,
        value: property.value
      });
    },
    updateGatewayExtensions({ listeners, properties }) {
      if (!this.selectedGatewayElement) {
        return;
      }
      try {
        const moddle = this.modeler.get("moddle");
        const businessObject = this.selectedGatewayElement.businessObject;
        const existingValues = businessObject.extensionElements?.values || [];
        const unmanagedValues = existingValues.filter((item) => item.$type !== "flowable:ExecutionListener" && item.$type !== "flowable:Properties");

        const nextValues = [...unmanagedValues];
        const propertyValues = (properties || []).map((item) => this.createPropertyObject(item));
        if (propertyValues.length) {
          nextValues.push(moddle.create("flowable:Properties", { values: propertyValues }));
        }
        nextValues.push(...(listeners || []).map((item) => this.createExecutionListenerObject(item)));

        const extensionElements = nextValues.length
          ? moddle.create("bpmn:ExtensionElements", { values: nextValues })
          : undefined;

        this.modeler.get("modeling").updateProperties(this.selectedGatewayElement, {
          extensionElements
        });
      } catch (error) {
        ElMessage.error(this.toImportError("更新节点扩展属性失败", error).details);
      }
    },
    normalizeXmlForImport(xml) {
      if (!xml) {
        return xml;
      }
      const parser = new DOMParser();
      const doc = parser.parseFromString(xml, "application/xml");
      if (doc.querySelector("parsererror")) {
        return xml;
      }

      const definitions = doc.getElementsByTagNameNS(BPMN_NS, "definitions")[0]
        || doc.getElementsByTagName("definitions")[0]
        || doc.documentElement;
      if (!definitions) {
        return xml;
      }

      const processElements = Array.from(doc.getElementsByTagNameNS(BPMN_NS, "process"));
      if (processElements.length !== 1) {
        return xml;
      }
      const process = processElements[0];
      const processId = (process.getAttribute("id") || this.processId || "Process_1").trim();
      if (!processId) {
        return xml;
      }

      if (!definitions.getAttribute("xmlns:bpmndi")) {
        definitions.setAttributeNS(XMLNS_NS, "xmlns:bpmndi", BPMNDI_NS);
      }
      if (!definitions.getAttribute("xmlns:dc")) {
        definitions.setAttributeNS(XMLNS_NS, "xmlns:dc", DC_NS);
      }
      if (!definitions.getAttribute("xmlns:di")) {
        definitions.setAttributeNS(XMLNS_NS, "xmlns:di", DI_NS);
      }

      let diagram = doc.getElementsByTagNameNS(BPMNDI_NS, "BPMNDiagram")[0];
      if (!diagram) {
        diagram = doc.createElementNS(BPMNDI_NS, "bpmndi:BPMNDiagram");
        diagram.setAttribute("id", "BPMNDiagram_1");
        definitions.appendChild(diagram);
      }

      let plane = doc.getElementsByTagNameNS(BPMNDI_NS, "BPMNPlane")[0];
      if (!plane) {
        plane = doc.createElementNS(BPMNDI_NS, "bpmndi:BPMNPlane");
        plane.setAttribute("id", "BPMNPlane_1");
        diagram.appendChild(plane);
      }

      if (!plane.getAttribute("bpmnElement")) {
        plane.setAttribute("bpmnElement", processId);
      }

      const hasRenderableDiagram = Array.from(plane.children || []).some((child) => {
        const localName = (child.localName || "").toLowerCase();
        return localName === "bpmnshape" || localName === "bpmnedge";
      });

      if (!hasRenderableDiagram) {
        this.generateAutoLayoutDi(doc, process, plane);
      }

      return new XMLSerializer().serializeToString(doc);
    },
    generateAutoLayoutDi(doc, process, plane) {
      while (plane.firstChild) {
        plane.removeChild(plane.firstChild);
      }

      const processChildren = Array.from(process.children || []);
      const nodes = processChildren
        .filter((element) => this.isFlowNodeElement(element))
        .map((element, index) => ({
          element,
          id: element.getAttribute("id"),
          type: (element.localName || "").toLowerCase(),
          index
        }))
        .filter((item) => Boolean(item.id));

      const nodeById = new Map(nodes.map((item) => [item.id, item]));
      const flows = processChildren
        .filter((element) => (element.localName || "").toLowerCase() === "sequenceflow")
        .map((element) => ({
          id: element.getAttribute("id"),
          sourceRef: element.getAttribute("sourceRef"),
          targetRef: element.getAttribute("targetRef")
        }))
        .filter((flow) => Boolean(flow.id && flow.sourceRef && flow.targetRef)
          && nodeById.has(flow.sourceRef)
          && nodeById.has(flow.targetRef));

      if (!nodes.length) {
        return;
      }

      const incoming = new Map(nodes.map((item) => [item.id, []]));
      const outgoing = new Map(nodes.map((item) => [item.id, []]));
      for (const flow of flows) {
        incoming.get(flow.targetRef).push(flow);
        outgoing.get(flow.sourceRef).push(flow);
      }

      const indegree = new Map(nodes.map((item) => [item.id, incoming.get(item.id).length]));
      const level = new Map();
      const queue = nodes
        .filter((item) => indegree.get(item.id) === 0)
        .sort((a, b) => a.index - b.index)
        .map((item) => item.id);

      if (!queue.length && nodes.length) {
        queue.push(nodes[0].id);
      }

      const visited = new Set();
      while (queue.length) {
        const currentId = queue.shift();
        if (!currentId || visited.has(currentId)) {
          continue;
        }
        visited.add(currentId);
        const currentLevel = level.get(currentId) || 0;
        const nextFlows = outgoing.get(currentId) || [];
        for (const flow of nextFlows) {
          const targetId = flow.targetRef;
          const prev = level.get(targetId) || 0;
          if (currentLevel + 1 > prev) {
            level.set(targetId, currentLevel + 1);
          }
          indegree.set(targetId, Math.max(0, (indegree.get(targetId) || 0) - 1));
          if ((indegree.get(targetId) || 0) === 0) {
            queue.push(targetId);
          }
        }
      }

      for (const node of nodes) {
        if (!level.has(node.id)) {
          const predecessors = incoming.get(node.id) || [];
          const inferred = predecessors.length
            ? Math.max(...predecessors.map((item) => level.get(item.sourceRef) || 0)) + 1
            : 0;
          level.set(node.id, inferred);
        }
      }

      const levels = new Map();
      for (const node of nodes) {
        const l = level.get(node.id) || 0;
        if (!levels.has(l)) {
          levels.set(l, []);
        }
        levels.get(l).push(node);
      }

      const positions = new Map();
      const orderedLevels = Array.from(levels.keys()).sort((a, b) => a - b);
      for (const l of orderedLevels) {
        const levelNodes = levels.get(l) || [];
        levelNodes.sort((a, b) => {
          const aPred = incoming.get(a.id) || [];
          const bPred = incoming.get(b.id) || [];
          const aScore = aPred.length
            ? aPred.reduce((sum, flow) => sum + (positions.get(flow.sourceRef)?.row || 0), 0) / aPred.length
            : a.index;
          const bScore = bPred.length
            ? bPred.reduce((sum, flow) => sum + (positions.get(flow.sourceRef)?.row || 0), 0) / bPred.length
            : b.index;
          if (aScore !== bScore) {
            return aScore - bScore;
          }
          return a.index - b.index;
        });

        levelNodes.forEach((node, row) => {
          positions.set(node.id, { level: l, row });
        });
      }

      const xStart = 140;
      const yStart = 90;
      const xGap = 220;
      const yGap = 140;
      const boundsByNode = new Map();

      for (const node of nodes) {
        const type = node.type;
        const pos = positions.get(node.id) || { level: 0, row: 0 };
        const size = this.getNodeSize(type);
        const x = xStart + pos.level * xGap;
        const y = yStart + pos.row * yGap;

        boundsByNode.set(node.id, {
          x,
          y,
          width: size.width,
          height: size.height
        });

        const shape = doc.createElementNS(BPMNDI_NS, "bpmndi:BPMNShape");
        shape.setAttribute("id", `${node.id}_di`);
        shape.setAttribute("bpmnElement", node.id);

        const bounds = doc.createElementNS(DC_NS, "dc:Bounds");
        bounds.setAttribute("x", String(x));
        bounds.setAttribute("y", String(y));
        bounds.setAttribute("width", String(size.width));
        bounds.setAttribute("height", String(size.height));

        shape.appendChild(bounds);
        plane.appendChild(shape);
      }

      for (const flow of flows) {
        const source = boundsByNode.get(flow.sourceRef);
        const target = boundsByNode.get(flow.targetRef);
        if (!source || !target) {
          continue;
        }

        const start = {
          x: source.x + source.width,
          y: source.y + source.height / 2
        };
        const end = {
          x: target.x,
          y: target.y + target.height / 2
        };

        const points = Math.abs(start.y - end.y) < 6
          ? [start, end]
          : [
            start,
            { x: (start.x + end.x) / 2, y: start.y },
            { x: (start.x + end.x) / 2, y: end.y },
            end
          ];

        const edge = doc.createElementNS(BPMNDI_NS, "bpmndi:BPMNEdge");
        edge.setAttribute("id", `${flow.id}_di`);
        edge.setAttribute("bpmnElement", flow.id);

        points.forEach((point) => {
          const waypoint = doc.createElementNS(DI_NS, "di:waypoint");
          waypoint.setAttribute("x", String(Math.round(point.x)));
          waypoint.setAttribute("y", String(Math.round(point.y)));
          edge.appendChild(waypoint);
        });

        plane.appendChild(edge);
      }
    },
    isFlowNodeElement(element) {
      const localName = (element?.localName || "").toLowerCase();
      if (!localName) {
        return false;
      }
      return !["sequenceflow", "lane", "laneset", "textannotation", "association", "group"].includes(localName);
    },
    getNodeSize(type) {
      if (["startevent", "endevent", "intermediatecatchevent", "intermediatethrowevent", "boundaryevent"].includes(type)) {
        return { width: 36, height: 36 };
      }
      if (["exclusivegateway", "parallelgateway", "inclusivegateway", "eventbasedgateway", "complexgateway"].includes(type)) {
        return { width: 50, height: 50 };
      }
      if (["subprocess", "callactivity"].includes(type)) {
        return { width: 140, height: 100 };
      }
      return { width: 120, height: 80 };
    },
    zoomIn() {
      if (!this.modeler) {
        return;
      }
      const next = Math.min(4, this.zoomLevel + 0.1);
      this.modeler.get("canvas").zoom(next);
    },
    zoomOut() {
      if (!this.modeler) {
        return;
      }
      const next = Math.max(0.2, this.zoomLevel - 0.1);
      this.modeler.get("canvas").zoom(next);
    },
    undo() {
      if (!this.modeler || !this.canUndo) {
        return;
      }
      this.modeler.get("commandStack").undo();
    },
    redo() {
      if (!this.modeler || !this.canRedo) {
        return;
      }
      this.modeler.get("commandStack").redo();
    },
    toImportError(message, error) {
      const detail = error && typeof error === "object" && "message" in error
        ? String(error.message)
        : String(error || message);
      return {
        message,
        details: detail
      };
    }
  }
};
</script>

<style scoped>
.bpmn-visual-designer {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
  min-width: 0;
}

.bpmn-visual-designer.is-fullscreen {
  height: 100%;
  min-height: 0;
}

.designer-toolbar {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.zoom-text {
  color: var(--text-subtle);
  font-size: 12px;
}

.designer-body {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 380px;
  gap: 12px;
  align-items: stretch;
  position: relative;
}

.designer-body.is-panel-hidden {
  grid-template-columns: minmax(0, 1fr);
}

.bpmn-visual-designer.is-fullscreen .designer-body {
  flex: 1;
  min-height: 0;
}

.designer-canvas {
  width: 100%;
  height: 460px;
  min-height: 460px;
  border: 1px solid rgba(148, 163, 184, 0.35);
  border-radius: 10px;
  background: #f8fafc;
  overflow: hidden;
}

.bpmn-visual-designer.is-fullscreen .designer-canvas {
  height: 100%;
  min-height: 0;
}

.gateway-panel {
  border: 1px solid rgba(148, 163, 184, 0.35);
  border-radius: 10px;
  background: #fff;
  padding: 12px;
  min-height: 460px;
  max-height: 460px;
  overflow: auto;
}

.bpmn-visual-designer.is-fullscreen .gateway-panel {
  min-height: 0;
  max-height: none;
  height: 100%;
}

.gateway-panel__head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.panel-head-actions {
  display: flex;
  align-items: center;
  gap: 6px;
}

.gateway-panel__title {
  font-size: 14px;
  font-weight: 600;
  color: #1f2937;
}

.panel-toggle-fab {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  z-index: 5;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.18);
}

.gateway-alert {
  margin-bottom: 10px;
}

.gateway-form {
  margin-bottom: 14px;
}

.gateway-section-title {
  font-size: 13px;
  color: #334155;
  margin-bottom: 8px;
  font-weight: 600;
}

.condition-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.condition-item {
  border: 1px solid rgba(148, 163, 184, 0.3);
  border-radius: 8px;
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  background: rgba(248, 250, 252, 0.8);
}

.condition-item__meta {
  display: flex;
  gap: 6px;
  align-items: center;
  color: #475569;
  font-size: 12px;
}

.gateway-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 8px;
}

.table-toolbar {
  margin-bottom: 8px;
  display: flex;
  justify-content: flex-end;
}

.field-toolbar {
  margin-bottom: 10px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.field-toolbar__title {
  font-size: 14px;
  font-weight: 600;
  color: #334155;
}

.designer-canvas :deep(.djs-container),
.designer-canvas :deep(.djs-container > svg),
.designer-canvas :deep(.djs-container .djs-svg) {
  width: 100% !important;
  height: 100% !important;
  min-height: 460px;
}

.bpmn-visual-designer.is-fullscreen .designer-canvas :deep(.djs-container),
.bpmn-visual-designer.is-fullscreen .designer-canvas :deep(.djs-container > svg),
.bpmn-visual-designer.is-fullscreen .designer-canvas :deep(.djs-container .djs-svg) {
  min-height: 0;
}

.designer-canvas :deep(.djs-container > svg) {
  display: block;
}

@media (max-width: 1360px) {
  .designer-body {
    grid-template-columns: 1fr;
  }

  .panel-toggle-fab {
    right: 10px;
    top: 12px;
    transform: none;
  }

  .gateway-panel {
    max-height: none;
    min-height: 320px;
  }

  .bpmn-visual-designer.is-fullscreen .gateway-panel {
    height: auto;
  }
}
</style>
