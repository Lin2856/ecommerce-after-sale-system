<template>
  <div class="panel knowledge-page">
    <div class="knowledge-overview">
      <div v-for="item in knowledgeMetrics" :key="item.label" class="knowledge-stat">
        <span>{{ item.label }}</span>
        <strong>{{ item.value }}</strong>
        <em>{{ item.description }}</em>
      </div>
    </div>
    <div class="toolbar knowledge-toolbar">
      <el-tabs v-model="active">
        <el-tab-pane :label="`常见问题解答 ${faqData.length}`" name="faq" />
        <el-tab-pane :label="`售后政策 ${ruleData.length}`" name="rules" />
      </el-tabs>
      <el-button type="primary" @click="openCreateDialog">新增</el-button>
    </div>
    <div class="knowledge-filter">
      <el-input v-model="searchKeyword" clearable placeholder="搜索问题、政策名称或内容" />
      <el-select v-model="categoryFilter" placeholder="全部分类">
        <el-option :label="active === 'rules' ? '全部政策' : '全部分类'" value="ALL" />
        <el-option v-for="item in categoryOptions" :key="item.value" :label="item.label" :value="item.value" />
      </el-select>
      <el-select v-model="enabledFilter" placeholder="启用状态">
        <el-option label="全部状态" value="ALL" />
        <el-option label="启用" value="ENABLED" />
        <el-option label="停用" value="DISABLED" />
      </el-select>
    </div>
    <el-table v-loading="loading" :data="filteredTableData" class="knowledge-table" height="calc(100vh - 282px)">
      <el-table-column :label="mainColumn.label" min-width="520">
        <template #default="{ row }">
          <div class="knowledge-main">
            <strong>{{ rowTitle(row) }}</strong>
            <span>{{ rowSummary(row) }}</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column :label="active === 'rules' ? '政策类型' : '分类'" width="180">
        <template #default="{ row }">
          <el-tag effect="light">{{ active === 'rules' ? ruleTypeText(row.ruleType) : categoryText(row.category) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="启用" width="100">
        <template #default="{ row }">
          <el-tag :type="row.enabled ? 'success' : 'info'">{{ row.enabled ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="210" fixed="right">
        <template #default="{ row }">
          <div class="knowledge-actions">
            <el-button link type="primary" @click="openDetailDialog(row)">详情</el-button>
            <el-button link type="primary" @click="openEditDialog(row)">编辑</el-button>
            <el-button link type="danger" @click="deleteKnowledge(row)">删除</el-button>
          </div>
        </template>
      </el-table-column>
    </el-table>
    <el-dialog v-model="detailVisible" :title="detailTitle" width="640px">
      <div class="policy-meta">
        <el-tag>{{ detailTypeText }}</el-tag>
        <el-tag :type="detailRow?.enabled ? 'success' : 'info'">{{ detailRow?.enabled ? '启用' : '停用' }}</el-tag>
      </div>
      <div class="policy-content">{{ detailContent }}</div>
      <template #footer>
        <el-button type="primary" @click="detailVisible = false">知道了</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px">
      <el-form label-width="88px">
        <el-form-item :label="mainColumn.label">
          <el-input v-model="knowledgeForm.title" />
        </el-form-item>
        <el-form-item :label="active === 'rules' ? '政策类型' : '分类'">
          <el-input v-model="knowledgeForm.category" />
        </el-form-item>
        <el-form-item label="启用">
          <el-switch v-model="knowledgeForm.enabled" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="内容">
          <el-input v-model="knowledgeForm.content" type="textarea" :rows="4" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveKnowledge">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { faqs, rules } from '../data/mock'
import { loadFaqs, loadRules } from '../api'
import { loadListWithFallback } from '../api/normalize'
import { ElMessage } from 'element-plus'

type KnowledgeMode = 'create' | 'edit'
type KnowledgeForm = {
  id: number | null
  title: string
  category: string
  content: string
  status: string
  enabled: boolean
}
const KNOWLEDGE_STORAGE_KEYS = {
  faq: 'merchant_knowledge_faq',
  rules: 'merchant_knowledge_rules'
} as const

const active = ref('faq')
const faqData = ref<typeof faqs>(faqs)
const ruleData = ref<typeof rules>(rules)
const loading = ref(false)
const dialogVisible = ref(false)
const detailVisible = ref(false)
const dialogMode = ref<KnowledgeMode>('create')
const knowledgeForm = ref<KnowledgeForm>(emptyForm())
const detailRow = ref<Record<string, unknown> | null>(null)
const categoryFilter = ref('ALL')
const enabledFilter = ref('ALL')
const searchKeyword = ref('')

async function loadCurrentTab() {
  loading.value = true
  if (active.value === 'faq') {
    const loadedFaqs = await loadKnowledgeList('faq', () => loadListWithFallback(() => loadFaqs(), faqs))
    faqData.value = mergeRequiredFaqs(loadedFaqs)
    saveKnowledgeList('faq', faqData.value)
  } else {
    const loadedRules = await loadKnowledgeList('rules', () => loadListWithFallback(() => loadRules(), rules))
    ruleData.value = mergeRequiredPolicies(loadedRules)
    saveKnowledgeList('rules', ruleData.value)
  }
  loading.value = false
}

onMounted(loadCurrentTab)
watch(active, () => {
  categoryFilter.value = 'ALL'
  enabledFilter.value = 'ALL'
  searchKeyword.value = ''
  loadCurrentTab()
})

const tableData = computed(() => {
  if (active.value === 'faq') {
    return faqData.value
  }
  if (active.value === 'rules') {
    return ruleData.value
  }
  return faqData.value
})

const filteredTableData = computed(() => {
  const keyword = searchKeyword.value.trim().toLowerCase()
  return tableData.value.filter((item) => {
    const matchCategory = categoryFilter.value === 'ALL' || categoryValue(item) === categoryFilter.value
    const matchEnabled = enabledFilter.value === 'ALL'
      || (enabledFilter.value === 'ENABLED' && Boolean(item.enabled))
      || (enabledFilter.value === 'DISABLED' && !item.enabled)
    const matchKeyword = !keyword
      || rowTitle(item).toLowerCase().includes(keyword)
      || rowSummary(item).toLowerCase().includes(keyword)
    return matchCategory && matchEnabled && matchKeyword
  })
})

const categoryOptions = computed(() => {
  const map = new Map<string, string>()
  tableData.value.forEach((item) => {
    const value = categoryValue(item)
    if (!value) return
    map.set(value, active.value === 'rules' ? ruleTypeText(value) : categoryText(value))
  })
  return Array.from(map.entries()).map(([value, label]) => ({ value, label }))
})

const categoryHeaderText = computed(() => {
  if (categoryFilter.value === 'ALL') {
    return active.value === 'rules' ? '政策类型' : '分类'
  }
  return active.value === 'rules' ? ruleTypeText(categoryFilter.value) : categoryText(categoryFilter.value)
})

const knowledgeMetrics = computed(() => {
  const faqTotal = faqData.value.length
  const ruleTotal = ruleData.value.length
  const enabled = [...faqData.value, ...ruleData.value].filter((item) => item.enabled).length
  const disabled = faqTotal + ruleTotal - enabled
  return [
    { label: '常见问题', value: faqTotal, description: '面向客服回复的问答内容' },
    { label: '售后政策', value: ruleTotal, description: '退货、退款、价保等规则' },
    { label: '启用内容', value: enabled, description: '当前可用于业务处理' },
    { label: '停用内容', value: disabled, description: '暂不参与客服回复' }
  ]
})

const mainColumn = computed(() => {
  if (active.value === 'faq') {
    return { prop: 'question', label: '问题' }
  }
  if (active.value === 'rules') {
    return { prop: 'ruleName', label: '政策名称' }
  }
  return { prop: 'question', label: '问题' }
})

const dialogTitle = computed(() => `${dialogMode.value === 'create' ? '新增' : '编辑'}${tabTitle.value}`)

const detailTitle = computed(() => String(detailRow.value?.ruleName || detailRow.value?.question || '内容详情'))

const detailContent = computed(() => String(detailRow.value?.content || detailRow.value?.answer || '暂无详细内容'))

const detailTypeText = computed(() => {
  if (detailRow.value?.ruleType) {
    return ruleTypeText(String(detailRow.value.ruleType))
  }
  return categoryText(String(detailRow.value?.category || 'GENERAL'))
})

const tabTitle = computed(() => {
  if (active.value === 'faq') {
    return '常见问题解答'
  }
  if (active.value === 'rules') {
    return '售后政策'
  }
  return '常见问题解答'
})

function emptyForm(): KnowledgeForm {
  return {
    id: null,
    title: '',
    category: '',
    content: '',
    status: 'PUBLISHED',
    enabled: true
  }
}

function openCreateDialog() {
  dialogMode.value = 'create'
  knowledgeForm.value = emptyForm()
  dialogVisible.value = true
}

function openEditDialog(row: Record<string, unknown>) {
  dialogMode.value = 'edit'
  knowledgeForm.value = {
    id: Number(row.id),
    title: String(row.title || row.question || row.ruleName || ''),
    category: String(row.category || row.ruleType || ''),
    content: String(row.content || row.answer || ''),
    status: String(row.status || 'PUBLISHED'),
    enabled: Boolean(row.enabled ?? true)
  }
  dialogVisible.value = true
}

function openDetailDialog(row: Record<string, unknown>) {
  detailRow.value = row
  detailVisible.value = true
}

function selectCategoryFilter(command: string | number | object) {
  categoryFilter.value = String(command)
}

function rowTitle(row: Record<string, unknown>) {
  return String(row.question || row.ruleName || row.title || '')
}

function rowSummary(row: Record<string, unknown>) {
  const text = String(row.answer || row.content || '暂无内容摘要')
  return text.length > 96 ? `${text.slice(0, 96)}...` : text
}

function saveKnowledge() {
  const title = knowledgeForm.value.title.trim()
  if (!title) {
    ElMessage({ type: 'warning', message: `请输入${mainColumn.value.label}` })
    return
  }
  if (dialogMode.value === 'edit') {
    updateKnowledge()
    return
  }
  createKnowledge()
}

function createKnowledge() {
  const title = knowledgeForm.value.title.trim()
  const createdAt = '2026-06-25 19:30:00'
  if (active.value === 'faq') {
    faqData.value = [{ id: Date.now(), question: title, answer: knowledgeForm.value.content, category: knowledgeForm.value.category || 'GENERAL', priority: 0, enabled: knowledgeForm.value.enabled, createdAt }, ...faqData.value]
    saveKnowledgeList('faq', faqData.value)
  } else if (active.value === 'rules') {
    ruleData.value = [{ id: Date.now(), ruleName: title, ruleType: knowledgeForm.value.category || 'CUSTOM', content: knowledgeForm.value.content, enabled: knowledgeForm.value.enabled, createdAt }, ...ruleData.value]
    saveKnowledgeList('rules', ruleData.value)
  }
  knowledgeForm.value = emptyForm()
  dialogVisible.value = false
  ElMessage({ type: 'success', message: '知识已新增' })
}

function updateKnowledge() {
  const id = knowledgeForm.value.id
  if (id == null) {
    return
  }
  if (active.value === 'faq') {
    faqData.value = faqData.value.map((item) => item.id === id
      ? { ...item, question: knowledgeForm.value.title, answer: knowledgeForm.value.content, category: knowledgeForm.value.category || 'GENERAL', enabled: knowledgeForm.value.enabled }
      : item)
    saveKnowledgeList('faq', faqData.value)
  } else if (active.value === 'rules') {
    ruleData.value = ruleData.value.map((item) => item.id === id
      ? { ...item, ruleName: knowledgeForm.value.title, ruleType: knowledgeForm.value.category || 'CUSTOM', content: knowledgeForm.value.content, enabled: knowledgeForm.value.enabled }
      : item)
    saveKnowledgeList('rules', ruleData.value)
  }
  knowledgeForm.value = emptyForm()
  dialogVisible.value = false
  ElMessage({ type: 'success', message: '知识已更新' })
}

function deleteKnowledge(row: Record<string, unknown>) {
  if (!window.confirm('删除后该知识内容将不再显示，确认删除吗？')) {
    return
  }
  const id = Number(row.id)
  if (active.value === 'faq') {
    faqData.value = faqData.value.filter((item) => item.id !== id)
    saveKnowledgeList('faq', faqData.value)
  } else if (active.value === 'rules') {
    ruleData.value = ruleData.value.filter((item) => item.id !== id)
    saveKnowledgeList('rules', ruleData.value)
  }
  ElMessage({ type: 'success', message: '知识已删除' })
}

async function loadKnowledgeList<T>(key: keyof typeof KNOWLEDGE_STORAGE_KEYS, fallbackLoader: () => Promise<T[]>) {
  const stored = readKnowledgeList<T>(key)
  if (stored.length) {
    return stored
  }
  const loaded = await fallbackLoader()
  saveKnowledgeList(key, loaded)
  return loaded
}

function readKnowledgeList<T>(key: keyof typeof KNOWLEDGE_STORAGE_KEYS) {
  const raw = localStorage.getItem(KNOWLEDGE_STORAGE_KEYS[key])
  if (!raw) {
    return []
  }
  try {
    return JSON.parse(raw) as T[]
  } catch {
    return []
  }
}

function saveKnowledgeList(key: keyof typeof KNOWLEDGE_STORAGE_KEYS, value: unknown[]) {
  localStorage.setItem(KNOWLEDGE_STORAGE_KEYS[key], JSON.stringify(value))
}

function categoryValue(row: Record<string, unknown>) {
  return String(active.value === 'rules' ? row.ruleType || '' : row.category || '')
}

function mergeRequiredPolicies(value: typeof rules) {
  const existingNames = new Set(value.map((item) => item.ruleName))
  const requiredPolicies = rules.filter((item) => !existingNames.has(item.ruleName))
  return [...requiredPolicies, ...value]
}

function mergeRequiredFaqs(value: typeof faqs) {
  const existingQuestions = new Set(value.map((item) => item.question))
  const requiredFaqs = faqs.filter((item) => !existingQuestions.has(item.question))
  return [...requiredFaqs, ...value]
}

function categoryText(value: string) {
  const map: Record<string, string> = {
    PRODUCT_POLICY: '商品政策',
    PLATFORM_POLICY: '平台政策',
    REFUND: '退款说明',
    AFTER_SALE: '售后处理',
    LOGISTICS: '物流说明',
    RETURN: '退货说明',
    PRICE_PROTECTION: '价格保护',
    EXCHANGE: '换货说明',
    REPAIR: '维修说明',
    CUSTOMER_SERVICE: '客服说明',
    GENERAL: '通用知识'
  }
  return map[value] || value
}

function ruleTypeText(value: string) {
  const map: Record<string, string> = {
    PRIORITY: '优先级规则',
    RETURN_POLICY: '退货政策',
    QUALITY_POLICY: '质量售后',
    REFUND_POLICY: '退款政策',
    RETURN_REFUND_POLICY: '退货退款',
    REPAIR_POLICY: '维修服务',
    PRICE_PROTECTION_POLICY: '价格保护',
    FREIGHT_INSURANCE_POLICY: '运费保障',
    SPECIAL_GOODS_POLICY: '特殊商品',
    REJECT_RECEIVE_POLICY: '拒收处理',
    PLATFORM_INTERVENTION_POLICY: '平台介入',
    REVIEW_RISK: '评价风险规则',
    CUSTOM: '自定义规则'
  }
  return map[value] || value
}

</script>

<style scoped>
.knowledge-page {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.knowledge-overview {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 12px;
}

.knowledge-stat {
  min-height: 70px;
  padding: 10px 14px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #fff;
}

.knowledge-stat span,
.knowledge-stat em {
  display: block;
}

.knowledge-stat span {
  color: #64748b;
  font-size: 13px;
}

.knowledge-stat strong {
  display: block;
  margin-top: 5px;
  color: #0f172a;
  font-size: 24px;
  line-height: 1;
}

.knowledge-stat em {
  margin-top: 6px;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
}

.knowledge-toolbar {
  align-items: center;
  margin-bottom: -4px;
  padding: 0;
}

.knowledge-toolbar :deep(.el-tabs__header) {
  margin: 0;
}

.knowledge-toolbar :deep(.el-tabs__nav-wrap::after) {
  height: 1px;
}

.knowledge-filter {
  display: grid;
  grid-template-columns: minmax(280px, 1fr) 180px 150px;
  gap: 12px;
  padding: 10px 14px;
  border: 1px solid #e4e8f0;
  border-radius: 8px;
  background: #fff;
}

.knowledge-table {
  border: 1px solid #e4e8f0;
  border-radius: 8px;
}

.knowledge-table :deep(.el-table__header th) {
  background: #f8fafc;
  color: #64748b;
  font-weight: 700;
}

.knowledge-table :deep(.el-table__row:hover > td) {
  background: #f6faff !important;
}

.knowledge-main {
  display: flex;
  min-width: 0;
  flex-direction: column;
  gap: 6px;
}

.knowledge-main strong {
  color: #0f172a;
  font-size: 15px;
  font-weight: 800;
}

.knowledge-main span {
  overflow: hidden;
  color: #64748b;
  font-size: 13px;
  line-height: 1.5;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.knowledge-actions {
  display: inline-flex;
  align-items: center;
  gap: 8px;
}

.policy-meta {
  display: flex;
  gap: 8px;
  margin-bottom: 14px;
}

.policy-content {
  color: #334155;
  line-height: 1.8;
  white-space: pre-wrap;
}

.filter-header {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: #606266;
  cursor: pointer;
}

.filter-arrow {
  font-size: 10px;
  color: #409eff;
}

@media (max-width: 1280px) {
  .knowledge-overview {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .knowledge-filter {
    grid-template-columns: 1fr;
  }
}
</style>
