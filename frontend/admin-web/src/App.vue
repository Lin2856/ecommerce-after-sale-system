<template>
  <el-container class="shell">
    <el-aside width="230px" class="aside">
      <div class="brand">平台管理后台</div>
      <button v-for="item in sections" :key="item" :class="{ active: active === item }" @click="active = item">{{ item }}</button>
    </el-aside>
    <el-container>
      <el-header class="header">
        <h1>{{ active }}</h1>
        <el-tag type="success">系统运行中</el-tag>
      </el-header>
      <el-main>
        <section v-if="active === '系统概览'" class="overview-page">
          <div class="overview-metrics">
            <div v-for="item in metrics" :key="item.label" class="card metric-card">
              <div class="metric-label">{{ item.label }}</div>
              <strong>{{ item.value }}</strong>
              <p>{{ item.description }}</p>
            </div>
          </div>
          <div class="overview-row">
            <div class="card overview-panel">
              <div class="panel-title">
                <h2>待处理事项</h2>
                <el-tag :type="pendingTotal > 0 ? 'warning' : 'success'">{{ pendingTotal > 0 ? '需要关注' : '暂无风险' }}</el-tag>
              </div>
              <div class="todo-list">
                <div v-for="item in pendingItems" :key="item.label" class="todo-item">
                  <div>
                    <strong>{{ item.value }}</strong>
                    <span>{{ item.label }}</span>
                  </div>
                  <el-tag :type="item.type">{{ item.status }}</el-tag>
                </div>
              </div>
            </div>
            <div class="card overview-panel">
              <div class="panel-title">
                <h2>数据同步状态</h2>
                <el-tag type="success">实时读取</el-tag>
              </div>
              <div class="sync-list">
                <div v-for="item in syncOverview" :key="item.task" class="sync-item">
                  <div class="sync-main">
                    <span>{{ item.task }}</span>
                    <strong>{{ formatNumber(item.count) }}</strong>
                  </div>
                  <div class="sync-sub">
                    <el-tag :type="item.status === '正常' ? 'success' : 'info'">{{ item.status }}</el-tag>
                    <span>{{ item.time || '暂无同步时间' }}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div class="overview-row wide-left">
            <div class="card overview-panel">
              <div class="panel-title">
                <h2>近 7 天业务趋势</h2>
                <span class="panel-subtitle">订单、售后、评价综合变化</span>
              </div>
              <div class="trend-chart">
                <div v-for="item in trendData" :key="item.date" class="trend-column">
                  <div class="trend-bars">
                    <span class="trend-bar order" :style="{ height: `${item.orderHeight}%` }"></span>
                    <span class="trend-bar after-sale" :style="{ height: `${item.afterSaleHeight}%` }"></span>
                    <span class="trend-bar review" :style="{ height: `${item.reviewHeight}%` }"></span>
                  </div>
                  <span class="trend-date">{{ item.date }}</span>
                </div>
              </div>
              <div class="chart-legend">
                <span><i class="legend-dot order"></i>订单</span>
                <span><i class="legend-dot after-sale"></i>售后</span>
                <span><i class="legend-dot review"></i>评价</span>
              </div>
            </div>
            <div class="card overview-panel">
              <div class="panel-title">
                <h2>平台账号绑定概览</h2>
                <span class="panel-subtitle">一级账号与二级平台账号</span>
              </div>
              <div class="binding-summary">
                <div v-for="item in bindingSummary" :key="item.label" class="binding-item">
                  <span>{{ item.label }}</span>
                  <strong>{{ item.value }}</strong>
                </div>
              </div>
              <el-table :data="platforms" size="small">
                <el-table-column label="平台" min-width="120">
                  <template #default="{ row }">
                    <div class="platform-cell">
                      <img class="platform-mini-icon" :src="row.icon" :alt="row.name" />
                      <span>{{ row.name }}</span>
                    </div>
                  </template>
                </el-table-column>
                <el-table-column prop="status" label="接入状态" width="100" />
                <el-table-column prop="shops" label="绑定店铺" width="100" />
              </el-table>
            </div>
          </div>
          <div class="card overview-panel">
            <div class="panel-title">
              <h2>最新系统动态</h2>
              <span class="panel-subtitle">根据数据库业务数据生成</span>
            </div>
            <div class="activity-list">
              <div v-for="item in recentActivities" :key="item.id" class="activity-item">
                <el-tag :type="item.type">{{ item.module }}</el-tag>
                <div>
                  <strong>{{ item.title }}</strong>
                  <p>{{ item.content }}</p>
                </div>
                <span>{{ item.time || '暂无时间' }}</span>
              </div>
            </div>
          </div>
        </section>
        <section v-else-if="active === '外部平台'" class="card">
          <el-table :data="platforms">
            <el-table-column label="图标" width="88">
              <template #default="{ row }">
                <img class="platform-icon" :src="row.icon" :alt="row.name" />
              </template>
            </el-table-column>
            <el-table-column prop="code" label="平台编码" />
            <el-table-column prop="name" label="平台名称" />
            <el-table-column prop="description" label="说明" />
            <el-table-column prop="status" label="状态" />
            <el-table-column prop="shops" label="绑定店铺数" />
          </el-table>
        </section>
        <section v-else-if="active === '同步监控'" class="card">
          <el-table :data="syncLogs">
            <el-table-column prop="task" label="任务" />
            <el-table-column prop="status" label="状态" />
            <el-table-column prop="count" label="数量" />
            <el-table-column prop="time" label="时间" />
          </el-table>
        </section>
        <section v-else-if="active === '用户管理'" class="card">
          <el-table :data="consumerBindings" border>
            <el-table-column label="头像" width="80">
              <template #default="{ row, $index }">
                <template v-if="shouldShowPrimaryCell(consumerBindings, row, $index)">
                  <el-avatar v-if="row.primaryAvatar" :size="36" :src="row.primaryAvatar" />
                  <el-avatar v-else :size="36">{{ avatarText(row.primaryDisplayName, row.primaryAccountNo) }}</el-avatar>
                </template>
              </template>
            </el-table-column>
            <el-table-column label="一级账号" min-width="160">
              <template #default="{ row, $index }">
                <span v-if="shouldShowPrimaryCell(consumerBindings, row, $index)">{{ row.primaryAccountNo }}</span>
              </template>
            </el-table-column>
            <el-table-column label="一级账号名称" min-width="180">
              <template #default="{ row, $index }">
                <span v-if="shouldShowPrimaryCell(consumerBindings, row, $index)">{{ row.primaryDisplayName }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="platformName" label="绑定平台" width="120" />
            <el-table-column prop="secondaryAccountNo" label="二级平台账号" min-width="160" />
            <el-table-column prop="secondaryDisplayName" label="二级账号名称" min-width="200" />
            <el-table-column prop="boundAt" label="绑定时间" min-width="180" />
          </el-table>
        </section>
        <section v-else-if="active === '商家管理'" class="card">
          <el-table :data="merchantBindings" border>
            <el-table-column label="头像" width="80">
              <template #default="{ row, $index }">
                <template v-if="shouldShowPrimaryCell(merchantBindings, row, $index)">
                  <el-avatar v-if="row.primaryAvatar" :size="36" :src="row.primaryAvatar" />
                  <el-avatar v-else :size="36">{{ avatarText(row.primaryDisplayName, row.primaryAccountNo) }}</el-avatar>
                </template>
              </template>
            </el-table-column>
            <el-table-column label="一级商家账号" min-width="180">
              <template #default="{ row, $index }">
                <span v-if="shouldShowPrimaryCell(merchantBindings, row, $index)">{{ row.primaryAccountNo }}</span>
              </template>
            </el-table-column>
            <el-table-column label="一级账号名称" min-width="180">
              <template #default="{ row, $index }">
                <span v-if="shouldShowPrimaryCell(merchantBindings, row, $index)">{{ row.primaryDisplayName }}</span>
              </template>
            </el-table-column>
            <el-table-column prop="platformName" label="绑定平台" width="120" />
            <el-table-column prop="secondaryAccountNo" label="二级平台账号" min-width="160" />
            <el-table-column prop="secondaryDisplayName" label="店铺名称" min-width="220" />
            <el-table-column prop="boundAt" label="绑定时间" min-width="180" />
          </el-table>
        </section>
        <section v-else-if="active === '知识库'" class="knowledge-page">
          <div class="knowledge-stats">
            <div v-for="item in knowledgeMetrics" :key="item.label" class="card knowledge-stat">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
            </div>
          </div>
          <div class="card">
            <div class="card-toolbar">
              <h2>知识库管理</h2>
              <div>
                <el-button @click="openFaqEditor()">新增常见问题</el-button>
                <el-button type="primary" @click="openArticleEditor()">新增知识文章</el-button>
              </div>
            </div>
            <el-tabs v-model="knowledgeTab">
              <el-tab-pane label="知识文章" name="articles">
                <el-table :data="knowledgeArticles" border>
                  <el-table-column prop="title" label="标题" min-width="220" />
                  <el-table-column prop="categoryText" label="分类" width="120" />
                  <el-table-column prop="statusText" label="状态" width="110" />
                  <el-table-column prop="tagsJson" label="标签" min-width="180" show-overflow-tooltip />
                  <el-table-column prop="content" label="内容摘要" min-width="260" show-overflow-tooltip />
                  <el-table-column prop="updatedAt" label="更新时间" min-width="160" />
                  <el-table-column label="操作" width="190" fixed="right">
                    <template #default="{ row }">
                      <el-button type="primary" link @click="selectedKnowledge = row">详细</el-button>
                      <el-button type="primary" link @click="openArticleEditor(row)">编辑</el-button>
                      <el-button type="danger" link @click="deleteArticle(row)">删除</el-button>
                    </template>
                  </el-table-column>
                </el-table>
              </el-tab-pane>
              <el-tab-pane label="常见问题" name="faqs">
                <el-table :data="faqItems" border>
                  <el-table-column prop="question" label="问题" min-width="260" />
                  <el-table-column prop="categoryText" label="分类" width="120" />
                  <el-table-column prop="priority" label="优先级" width="90" />
                  <el-table-column label="启用状态" width="120">
                    <template #default="{ row }">
                      <el-switch v-model="row.enabled" active-text="启用" inactive-text="停用" @change="toggleFaq(row)" />
                    </template>
                  </el-table-column>
                  <el-table-column prop="answer" label="答案摘要" min-width="280" show-overflow-tooltip />
                  <el-table-column prop="updatedAt" label="更新时间" min-width="160" />
                  <el-table-column label="操作" width="190" fixed="right">
                    <template #default="{ row }">
                      <el-button type="primary" link @click="selectedFaq = row">详细</el-button>
                      <el-button type="primary" link @click="openFaqEditor(row)">编辑</el-button>
                      <el-button type="danger" link @click="deleteFaq(row)">删除</el-button>
                    </template>
                  </el-table-column>
                </el-table>
              </el-tab-pane>
            </el-tabs>
          </div>
        </section>
        <section v-else-if="active === '规则配置'" class="rule-page">
          <div class="rule-stats">
            <div v-for="item in ruleMetrics" :key="item.label" class="card rule-stat">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
            </div>
          </div>
          <div class="card">
            <div class="card-toolbar">
              <h2>售后规则配置</h2>
              <el-button type="primary" @click="openRuleEditor()">新增规则</el-button>
            </div>
            <el-table :data="adminRules" border>
              <el-table-column prop="ruleName" label="规则名称" min-width="180" />
              <el-table-column prop="ruleTypeText" label="规则类型" width="130" />
              <el-table-column prop="content" label="规则说明" min-width="260" show-overflow-tooltip />
              <el-table-column prop="conditionsText" label="触发条件" min-width="220" show-overflow-tooltip />
              <el-table-column prop="actionText" label="执行动作" min-width="220" show-overflow-tooltip />
              <el-table-column label="启用状态" width="120">
                <template #default="{ row }">
                  <el-switch
                    v-model="row.enabled"
                    active-text="启用"
                    inactive-text="停用"
                    @change="toggleRule(row)"
                  />
                </template>
              </el-table-column>
              <el-table-column prop="updatedAt" label="更新时间" min-width="160" />
              <el-table-column label="操作" width="140" fixed="right">
                <template #default="{ row }">
                  <el-button type="primary" link @click="openRuleEditor(row)">编辑</el-button>
                  <el-button type="danger" link @click="deleteRule(row)">删除</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </section>
        <section v-else-if="active === '评价分析'" class="review-page">
          <div class="review-stats">
            <div v-for="item in reviewMetrics" :key="item.label" class="card review-stat">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
            </div>
          </div>
          <div class="card">
            <el-table :data="adminReviews" border>
              <el-table-column prop="platform" label="平台" width="96" />
              <el-table-column prop="orderNo" label="订单号" min-width="150" />
              <el-table-column prop="merchantName" label="商家" min-width="170" />
              <el-table-column prop="productName" label="商品" min-width="180" />
              <el-table-column label="星级" width="130">
                <template #default="{ row }">
                  <el-rate :model-value="row.score" disabled size="small" />
                </template>
              </el-table-column>
              <el-table-column prop="content" label="评价内容" min-width="260" show-overflow-tooltip />
              <el-table-column prop="sentiment" label="情感" width="96">
                <template #default="{ row }">
                  <el-tag :type="sentimentTagType(row.sentiment)">{{ row.sentiment }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="riskLevel" label="风险" width="96">
                <template #default="{ row }">
                  <el-tag :type="riskTagType(row.riskLevel)">{{ row.riskLevel }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="异议状态" width="112">
                <template #default="{ row }">
                  <el-tag :type="disputeTagType(row.disputeStatus)">{{ row.disputeStatus || '未提出' }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="120">
                <template #default="{ row }">
                  <el-button type="primary" link @click="selectedReview = row">详细</el-button>
                </template>
              </el-table-column>
            </el-table>
          </div>
        </section>
        <section v-else-if="active === 'AI 配置'" class="ai-config-page">
          <div class="card">
            <div class="card-toolbar">
              <h2>AI 服务运行配置</h2>
              <el-button type="primary" :loading="aiConfigLoading" @click="loadAiConfig">刷新配置</el-button>
            </div>
            <el-descriptions border :column="1">
              <el-descriptions-item label="服务状态">
                <el-tag :type="aiConfig.healthy ? 'success' : 'danger'">{{ aiConfig.healthy ? '运行中' : '不可用' }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="服务名称">{{ aiConfig.serviceName || '暂无数据' }}</el-descriptions-item>
              <el-descriptions-item label="服务地址">{{ aiConfig.serviceUrl }}</el-descriptions-item>
              <el-descriptions-item label="服务版本">{{ aiConfig.serviceVersion || '暂无数据' }}</el-descriptions-item>
              <el-descriptions-item label="模型提供商">{{ providerText(aiConfig.provider) }}</el-descriptions-item>
              <el-descriptions-item label="模型名称">{{ aiConfig.modelName || '暂无数据' }}</el-descriptions-item>
              <el-descriptions-item label="模型接口地址">{{ aiConfig.baseUrl || '暂无数据' }}</el-descriptions-item>
              <el-descriptions-item label="API Key 状态">
                <el-tag :type="aiConfig.apiKeyConfigured ? 'success' : 'warning'">
                  {{ aiConfig.apiKeyConfigured ? '已配置' : '未配置' }}
                </el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="回复模式">{{ aiConfig.replyMode || '暂无数据' }}</el-descriptions-item>
              <el-descriptions-item label="兜底策略">{{ aiConfig.fallbackMode || '暂无数据' }}</el-descriptions-item>
              <el-descriptions-item label="最大 Token">{{ aiConfig.maxTokens }}</el-descriptions-item>
              <el-descriptions-item label="超时时间">{{ aiConfig.timeoutSeconds }} 秒</el-descriptions-item>
              <el-descriptions-item label="最近检测时间">{{ aiConfig.checkedAt || '尚未检测' }}</el-descriptions-item>
            </el-descriptions>
          </div>
        </section>
        <section v-else class="card">
          <h2>{{ active }}</h2>
          <p>该模块已预留管理入口，后续接入真实接口。</p>
        </section>
      </el-main>
    </el-container>
    <el-dialog v-model="reviewDetailVisible" title="评价分析详细" width="720px">
      <el-descriptions v-if="selectedReview" border :column="2">
        <el-descriptions-item label="平台">{{ selectedReview.platform }}</el-descriptions-item>
        <el-descriptions-item label="订单号">{{ selectedReview.orderNo }}</el-descriptions-item>
        <el-descriptions-item label="商家">{{ selectedReview.merchantName }}</el-descriptions-item>
        <el-descriptions-item label="商品">{{ selectedReview.productName }}</el-descriptions-item>
        <el-descriptions-item label="产品质量星级">{{ selectedReview.productScore }} 星</el-descriptions-item>
        <el-descriptions-item label="商家服务星级">{{ selectedReview.serviceScore }} 星</el-descriptions-item>
        <el-descriptions-item label="情感">{{ selectedReview.sentiment }}</el-descriptions-item>
        <el-descriptions-item label="风险">{{ selectedReview.riskLevel }}</el-descriptions-item>
        <el-descriptions-item label="关键词" :span="2">{{ selectedReview.keywords }}</el-descriptions-item>
        <el-descriptions-item label="评价时间" :span="2">{{ selectedReview.reviewedAt }}</el-descriptions-item>
        <el-descriptions-item label="评价内容" :span="2">{{ selectedReview.content }}</el-descriptions-item>
        <el-descriptions-item label="分析摘要" :span="2">{{ selectedReview.analysisSummary }}</el-descriptions-item>
        <el-descriptions-item label="处理建议" :span="2">{{ selectedReview.suggestion }}</el-descriptions-item>
        <el-descriptions-item label="异议状态">{{ selectedReview.disputeStatus || '未提出' }}</el-descriptions-item>
        <el-descriptions-item label="异议提交时间">{{ selectedReview.disputeCreatedAt || '暂无' }}</el-descriptions-item>
        <el-descriptions-item label="商家异议原因" :span="2">{{ selectedReview.disputeReason || '暂无' }}</el-descriptions-item>
        <el-descriptions-item label="管理员审核说明" :span="2">{{ selectedReview.disputeAdminNote || '暂无' }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="selectedReview = null">关闭</el-button>
        <el-button
          v-if="selectedReview?.disputeStatus === '待审核'"
          type="success"
          :loading="reviewingDispute"
          @click="reviewSelectedDispute('APPROVE')"
        >
          通过并删除评价
        </el-button>
        <el-button
          v-if="selectedReview?.disputeStatus === '待审核'"
          type="warning"
          :loading="reviewingDispute"
          @click="reviewSelectedDispute('REJECT')"
        >
          拒绝异议
        </el-button>
        <el-button v-if="selectedReview" type="danger" :loading="deletingReview" @click="deleteSelectedReview">
          删除评价
        </el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="ruleEditorVisible" :title="ruleForm.id ? '编辑售后规则' : '新增售后规则'" width="720px">
      <el-form label-width="96px">
        <el-form-item label="规则名称">
          <el-input v-model="ruleForm.ruleName" placeholder="请输入规则名称" />
        </el-form-item>
        <el-form-item label="规则类型">
          <el-select v-model="ruleForm.ruleType" placeholder="请选择规则类型" style="width: 100%">
            <el-option label="退货政策" value="RETURN_POLICY" />
            <el-option label="退款政策" value="REFUND_POLICY" />
            <el-option label="价保政策" value="PRICE_PROTECTION" />
            <el-option label="运费险政策" value="FREIGHT_INSURANCE" />
            <el-option label="优先级规则" value="PRIORITY" />
            <el-option label="人工审核规则" value="MANUAL_REVIEW" />
          </el-select>
        </el-form-item>
        <el-form-item label="启用状态">
          <el-switch v-model="ruleForm.enabled" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="触发条件">
          <el-input v-model="ruleForm.conditionsJson" type="textarea" :rows="4" placeholder='例如：{"days":7}' />
        </el-form-item>
        <el-form-item label="执行动作">
          <el-input v-model="ruleForm.actionJson" type="textarea" :rows="4" placeholder='例如：{"allowReturn":true}' />
        </el-form-item>
        <el-form-item label="规则说明">
          <el-input v-model="ruleForm.content" type="textarea" :rows="4" placeholder="请输入规则说明" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="ruleEditorVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingRule" @click="saveRule">保存</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="knowledgeDetailVisible" title="知识文章详细" width="720px">
      <el-descriptions v-if="selectedKnowledge" border :column="2">
        <el-descriptions-item label="标题" :span="2">{{ selectedKnowledge.title }}</el-descriptions-item>
        <el-descriptions-item label="分类">{{ selectedKnowledge.categoryText }}</el-descriptions-item>
        <el-descriptions-item label="状态">{{ selectedKnowledge.statusText }}</el-descriptions-item>
        <el-descriptions-item label="标签" :span="2">{{ selectedKnowledge.tagsJson }}</el-descriptions-item>
        <el-descriptions-item label="更新时间" :span="2">{{ selectedKnowledge.updatedAt }}</el-descriptions-item>
        <el-descriptions-item label="内容" :span="2">{{ selectedKnowledge.content }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
    <el-dialog v-model="faqDetailVisible" title="常见问题详细" width="720px">
      <el-descriptions v-if="selectedFaq" border :column="2">
        <el-descriptions-item label="问题" :span="2">{{ selectedFaq.question }}</el-descriptions-item>
        <el-descriptions-item label="分类">{{ selectedFaq.categoryText }}</el-descriptions-item>
        <el-descriptions-item label="优先级">{{ selectedFaq.priority }}</el-descriptions-item>
        <el-descriptions-item label="启用状态">{{ selectedFaq.enabled ? '启用' : '停用' }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ selectedFaq.updatedAt }}</el-descriptions-item>
        <el-descriptions-item label="答案" :span="2">{{ selectedFaq.answer }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
    <el-dialog v-model="articleEditorVisible" :title="articleForm.id ? '编辑知识文章' : '新增知识文章'" width="720px">
      <el-form label-width="96px">
        <el-form-item label="标题"><el-input v-model="articleForm.title" /></el-form-item>
        <el-form-item label="分类">
          <el-select v-model="articleForm.category" style="width: 100%">
            <el-option label="平台政策" value="PLATFORM_POLICY" />
            <el-option label="商品政策" value="PRODUCT_POLICY" />
            <el-option label="售后政策" value="AFTER_SALE_POLICY" />
            <el-option label="客服话术" value="SERVICE_SCRIPT" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="articleForm.status" style="width: 100%">
            <el-option label="已发布" value="PUBLISHED" />
            <el-option label="草稿" value="DRAFT" />
            <el-option label="已停用" value="DISABLED" />
          </el-select>
        </el-form-item>
        <el-form-item label="标签">
          <el-input v-model="articleForm.tagsJson" placeholder='例如：["退货","售后"]' />
        </el-form-item>
        <el-form-item label="内容">
          <el-input v-model="articleForm.content" type="textarea" :rows="8" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="articleEditorVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingKnowledge" @click="saveArticle">保存</el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="faqEditorVisible" :title="faqForm.id ? '编辑常见问题' : '新增常见问题'" width="720px">
      <el-form label-width="96px">
        <el-form-item label="问题"><el-input v-model="faqForm.question" /></el-form-item>
        <el-form-item label="分类">
          <el-select v-model="faqForm.category" style="width: 100%">
            <el-option label="退款问题" value="REFUND" />
            <el-option label="售后问题" value="AFTER_SALE" />
            <el-option label="退货问题" value="RETURN" />
            <el-option label="物流问题" value="LOGISTICS" />
            <el-option label="账号问题" value="ACCOUNT" />
          </el-select>
        </el-form-item>
        <el-form-item label="优先级"><el-input-number v-model="faqForm.priority" :min="0" :max="999" /></el-form-item>
        <el-form-item label="启用状态"><el-switch v-model="faqForm.enabled" active-text="启用" inactive-text="停用" /></el-form-item>
        <el-form-item label="答案"><el-input v-model="faqForm.answer" type="textarea" :rows="8" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="faqEditorVisible = false">取消</el-button>
        <el-button type="primary" :loading="savingKnowledge" @click="saveFaq">保存</el-button>
      </template>
    </el-dialog>
  </el-container>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { ElMessage } from 'element-plus/es/components/message/index'
import { ElMessageBox } from 'element-plus/es/components/message-box/index'
import douyinIcon from './assets/platforms/douyin.png'
import jdIcon from './assets/platforms/jd.png'
import pddIcon from './assets/platforms/pinduoduo.png'
import taobaoIcon from './assets/platforms/taobao.png'
import twentyMallIcon from './assets/platforms/twenty-mall.png'

const sections = ['系统概览', '用户管理', '商家管理', '外部平台', '同步监控', '知识库', '规则配置', '评价分析', 'AI 配置']
const active = ref('系统概览')
const aiConfigLoading = ref(false)
const aiConfig = ref({
  healthy: false,
  serviceName: '',
  serviceVersion: '',
  serviceUrl: 'http://localhost:9000',
  provider: '',
  modelName: '',
  baseUrl: '',
  apiKeyConfigured: false,
  replyMode: '',
  fallbackMode: '',
  maxTokens: 0,
  timeoutSeconds: 0,
  checkedAt: ''
})
const overview = ref({
  merchantCount: 0,
  boundShopCount: 0,
  todaySyncCount: 0,
  pendingAfterSaleCount: 0,
  processingAfterSaleCount: 0,
  highRiskReviewCount: 0,
  activeRuleCount: 0,
  knowledgeCount: 0,
  trendRows: [] as TrendRow[],
  activityRows: [] as ActivityRow[]
})
type TrendRow = {
  date: string
  orderCount: number
  afterSaleCount: number
  reviewCount: number
}
type ActivityRow = {
  id: number
  module: string
  title: string
  content: string
  time: string
}
type BindingRow = {
  primaryAccountNo: string
  primaryDisplayName: string
  primaryAvatar?: string
  platformName: string
  secondaryAccountNo: string
  secondaryDisplayName: string
  bindStatus: string
  secondaryStatus: string
  boundAt: string
}
type SyncLogRow = {
  task: string
  status: string
  count: number
  time: string
}
type ReviewRow = {
  id: number
  platform: string
  orderNo: string
  merchantName: string
  productName: string
  productScore: number
  serviceScore: number
  score: number
  content: string
  sentiment: string
  riskLevel: string
  keywords: string
  analysisSummary: string
  suggestion: string
  reviewedAt: string
  disputeId?: number | null
  disputeStatus?: string
  disputeReason?: string
  disputeAdminNote?: string
  disputeCreatedAt?: string
}
type RuleRow = {
  id: number
  ruleName: string
  ruleType: string
  ruleTypeText: string
  conditionsJson: string
  conditionsText: string
  actionJson: string
  actionText: string
  content: string
  enabled: boolean
  updatedAt: string
}
type KnowledgeArticleRow = {
  id: number
  title: string
  content: string
  category: string
  categoryText: string
  tagsJson: string
  status: string
  statusText: string
  updatedAt: string
}
type FaqRow = {
  id: number
  question: string
  answer: string
  category: string
  categoryText: string
  priority: number
  enabled: boolean
  updatedAt: string
}
const consumerBindings = ref<BindingRow[]>([])
const merchantBindings = ref<BindingRow[]>([])
const syncLogs = ref<SyncLogRow[]>([])
const adminReviews = ref<ReviewRow[]>([])
const adminRules = ref<RuleRow[]>([])
const knowledgeArticles = ref<KnowledgeArticleRow[]>([])
const faqItems = ref<FaqRow[]>([])
const selectedReview = ref<ReviewRow | null>(null)
const selectedKnowledge = ref<KnowledgeArticleRow | null>(null)
const selectedFaq = ref<FaqRow | null>(null)
const deletingReview = ref(false)
const reviewingDispute = ref(false)
const ruleEditorVisible = ref(false)
const savingRule = ref(false)
const knowledgeTab = ref('articles')
const articleEditorVisible = ref(false)
const faqEditorVisible = ref(false)
const savingKnowledge = ref(false)
const ruleForm = ref<RuleRow>({
  id: 0,
  ruleName: '',
  ruleType: 'RETURN_POLICY',
  ruleTypeText: '退货政策',
  conditionsJson: '{}',
  conditionsText: '无特殊触发条件',
  actionJson: '{}',
  actionText: '记录规则命中结果',
  content: '',
  enabled: true,
  updatedAt: ''
})
const articleForm = ref<KnowledgeArticleRow>({
  id: 0,
  title: '',
  content: '',
  category: 'PLATFORM_POLICY',
  categoryText: '平台政策',
  tagsJson: '[]',
  status: 'PUBLISHED',
  statusText: '已发布',
  updatedAt: ''
})
const faqForm = ref<FaqRow>({
  id: 0,
  question: '',
  answer: '',
  category: 'AFTER_SALE',
  categoryText: '售后问题',
  priority: 0,
  enabled: true,
  updatedAt: ''
})
const reviewDetailVisible = computed({
  get: () => selectedReview.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedReview.value = null
    }
  }
})
const knowledgeDetailVisible = computed({
  get: () => selectedKnowledge.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedKnowledge.value = null
    }
  }
})
const faqDetailVisible = computed({
  get: () => selectedFaq.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedFaq.value = null
    }
  }
})
const metrics = computed(() => [
  { label: '商家数', value: formatNumber(overview.value.merchantCount), description: '20商城中已启用的商家账号' },
  { label: '绑定店铺', value: formatNumber(overview.value.boundShopCount), description: '商家一级账号已绑定的店铺数量' },
  { label: '今日同步', value: formatNumber(overview.value.todaySyncCount), description: '今日更新的订单、售后和评价数据' },
  { label: 'AI 调用', value: formatNumber(aiCallCount.value), description: '基于会话和评价分析估算的调用量' }
])
const aiCallCount = computed(() => adminReviews.value.length + overview.value.processingAfterSaleCount + overview.value.pendingAfterSaleCount)
const pendingItems = computed(() => [
  {
    label: '待审核售后',
    value: formatNumber(overview.value.pendingAfterSaleCount),
    status: overview.value.pendingAfterSaleCount > 0 ? '待处理' : '正常',
    type: overview.value.pendingAfterSaleCount > 0 ? 'warning' : 'success'
  },
  {
    label: '处理中售后',
    value: formatNumber(overview.value.processingAfterSaleCount),
    status: overview.value.processingAfterSaleCount > 0 ? '跟进中' : '正常',
    type: overview.value.processingAfterSaleCount > 0 ? 'primary' : 'success'
  },
  {
    label: '高风险评价',
    value: formatNumber(overview.value.highRiskReviewCount),
    status: overview.value.highRiskReviewCount > 0 ? '需复核' : '正常',
    type: overview.value.highRiskReviewCount > 0 ? 'danger' : 'success'
  },
  {
    label: '启用规则',
    value: formatNumber(overview.value.activeRuleCount),
    status: overview.value.activeRuleCount > 0 ? '已配置' : '待配置',
    type: overview.value.activeRuleCount > 0 ? 'success' : 'info'
  }
])
const pendingTotal = computed(() => overview.value.pendingAfterSaleCount + overview.value.highRiskReviewCount)
const syncOverview = computed(() => syncLogs.value.length > 0 ? syncLogs.value : [
  { task: '20商城订单数据同步', status: '暂无数据', count: 0, time: '' },
  { task: '20商城售后数据同步', status: '暂无数据', count: 0, time: '' },
  { task: '20商城评价数据同步', status: '暂无数据', count: 0, time: '' }
])
const bindingSummary = computed(() => [
  { label: '消费者一级账号', value: formatNumber(countUniquePrimary(consumerBindings.value)) },
  { label: '商家一级账号', value: formatNumber(countUniquePrimary(merchantBindings.value)) },
  { label: '绑定消费者账号', value: formatNumber(consumerBindings.value.length) },
  { label: '绑定商家店铺', value: formatNumber(merchantBindings.value.length) }
])
const trendData = computed(() => {
  const rows = overview.value.trendRows.length > 0
    ? overview.value.trendRows
    : Array.from({ length: 7 }, (_, index) => ({ date: `近${7 - index}日`, orderCount: 0, afterSaleCount: 0, reviewCount: 0 }))
  const maxValue = Math.max(1, ...rows.flatMap((item) => [item.orderCount, item.afterSaleCount, item.reviewCount]))
  return rows.map((item) => ({
    ...item,
    orderHeight: Math.max(6, Math.round((item.orderCount / maxValue) * 100)),
    afterSaleHeight: Math.max(6, Math.round((item.afterSaleCount / maxValue) * 100)),
    reviewHeight: Math.max(6, Math.round((item.reviewCount / maxValue) * 100))
  }))
})
const recentActivities = computed(() => {
  if (overview.value.activityRows.length > 0) {
    return overview.value.activityRows.map((item) => ({ ...item, type: activityTagType(item.module) }))
  }
  return [
    { id: 1, module: '系统', title: '暂无最新业务动态', content: '当前数据库中暂未读取到近期评价、规则或知识库更新记录。', time: '', type: 'info' }
  ]
})
const reviewMetrics = computed(() => {
  const total = adminReviews.value.length
  const highRisk = adminReviews.value.filter((item) => item.riskLevel === '高风险').length
  const negative = adminReviews.value.filter((item) => item.sentiment === '负向').length
  const averageScore = total === 0
    ? '0.0'
    : (adminReviews.value.reduce((sum, item) => sum + item.score, 0) / total).toFixed(1)
  return [
    { label: '评价总数', value: formatNumber(total) },
    { label: '平均星级', value: averageScore },
    { label: '负向评价', value: formatNumber(negative) },
    { label: '高风险评价', value: formatNumber(highRisk) }
  ]
})
const ruleMetrics = computed(() => {
  const total = adminRules.value.length
  const enabled = adminRules.value.filter((item) => item.enabled).length
  const disabled = total - enabled
  const types = new Set(adminRules.value.map((item) => item.ruleType)).size
  return [
    { label: '规则总数', value: formatNumber(total) },
    { label: '已启用', value: formatNumber(enabled) },
    { label: '已停用', value: formatNumber(disabled) },
    { label: '规则类型', value: formatNumber(types) }
  ]
})
const knowledgeMetrics = computed(() => {
  const articleTotal = knowledgeArticles.value.length
  const published = knowledgeArticles.value.filter((item) => item.status === 'PUBLISHED').length
  const faqTotal = faqItems.value.length
  const enabledFaq = faqItems.value.filter((item) => item.enabled).length
  return [
    { label: '知识文章', value: formatNumber(articleTotal) },
    { label: '已发布文章', value: formatNumber(published) },
    { label: '常见问题', value: formatNumber(faqTotal) },
    { label: '启用 FAQ', value: formatNumber(enabledFaq) }
  ]
})
const platforms = computed(() => {
  const twentyMallShopCount = countUniqueBoundShops('20商城')
  return [
    { code: 'DOUYIN', name: '抖音电商', description: '真实抖店开放平台待接入', status: '未接入', shops: 0, icon: douyinIcon },
    { code: 'TAOBAO', name: '淘宝', description: '预留淘宝开放平台接入', status: '规划中', shops: 0, icon: taobaoIcon },
    { code: 'PDD', name: '拼多多', description: '预留拼多多开放平台接入', status: '规划中', shops: 0, icon: pddIcon },
    { code: 'JD', name: '京东', description: '预留京东开放平台接入', status: '规划中', shops: 0, icon: jdIcon },
    {
      code: 'TWENTY_MALL',
      name: '20商城',
      description: '自建数据库模拟真实电商平台，提供订单、售后、评价等演示数据',
      status: twentyMallShopCount > 0 ? '启用' : '未绑定',
      shops: twentyMallShopCount,
      icon: twentyMallIcon
    }
  ]
})
onMounted(() => {
  loadOverview()
  loadAccountBindings()
  loadSyncLogs()
  loadAdminReviews()
  loadAdminRules()
  loadKnowledge()
  loadAiConfig()
})

async function loadAiConfig() {
  aiConfigLoading.value = true
  const checkedAt = formatLocalDateTime(new Date())
  try {
    const healthResponse = await fetch('http://localhost:9000/health')
    if (!healthResponse.ok) {
      throw new Error('AI 服务健康检查失败')
    }
    const configResponse = await fetch('http://localhost:9000/api/ai/config')
    if (!configResponse.ok) {
      throw new Error('AI 配置接口不可用')
    }
    const payload = await configResponse.json()
    aiConfig.value = {
      healthy: true,
      serviceName: payload.serviceName || '',
      serviceVersion: payload.serviceVersion || '',
      serviceUrl: payload.serviceUrl || 'http://localhost:9000',
      provider: payload.provider || '',
      modelName: payload.modelName || '',
      baseUrl: payload.baseUrl || '',
      apiKeyConfigured: Boolean(payload.apiKeyConfigured),
      replyMode: payload.replyMode || '',
      fallbackMode: payload.fallbackMode || '',
      maxTokens: Number(payload.maxTokens || 0),
      timeoutSeconds: Number(payload.timeoutSeconds || 0),
      checkedAt
    }
  } catch {
    aiConfig.value = {
      ...aiConfig.value,
      healthy: false,
      checkedAt
    }
  } finally {
    aiConfigLoading.value = false
  }
}

async function loadOverview() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/overview')
    const payload = await response.json()
    if (payload.code === '200' && payload.data) {
      overview.value = {
        merchantCount: Number(payload.data.merchantCount || 0),
        boundShopCount: Number(payload.data.boundShopCount || 0),
        todaySyncCount: Number(payload.data.todaySyncCount || 0),
        pendingAfterSaleCount: Number(payload.data.pendingAfterSaleCount || 0),
        processingAfterSaleCount: Number(payload.data.processingAfterSaleCount || 0),
        highRiskReviewCount: Number(payload.data.highRiskReviewCount || 0),
        activeRuleCount: Number(payload.data.activeRuleCount || 0),
        knowledgeCount: Number(payload.data.knowledgeCount || 0),
        trendRows: (payload.data.trendRows || []).map((item: TrendRow) => ({
          date: item.date,
          orderCount: Number(item.orderCount || 0),
          afterSaleCount: Number(item.afterSaleCount || 0),
          reviewCount: Number(item.reviewCount || 0)
        })),
        activityRows: (payload.data.activityRows || []).map((item: ActivityRow) => ({
          id: Number(item.id || 0),
          module: item.module || '',
          title: item.title || '',
          content: item.content || '',
          time: item.time || ''
        }))
      }
    }
  } catch {
    overview.value = {
      merchantCount: 0,
      boundShopCount: 0,
      todaySyncCount: 0,
      pendingAfterSaleCount: 0,
      processingAfterSaleCount: 0,
      highRiskReviewCount: 0,
      activeRuleCount: 0,
      knowledgeCount: 0,
      trendRows: [],
      activityRows: []
    }
  }
}

async function loadAccountBindings() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/account-bindings')
    const payload = await response.json()
    if (payload.code === '200' && payload.data) {
      consumerBindings.value = payload.data.consumerBindings || []
      merchantBindings.value = payload.data.merchantBindings || []
    }
  } catch {
    consumerBindings.value = []
    merchantBindings.value = []
  }
}

async function loadSyncLogs() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/sync-monitor')
    const payload = await response.json()
    if (payload.code === '200' && Array.isArray(payload.data)) {
      syncLogs.value = payload.data.map((item: SyncLogRow) => ({
        task: item.task,
        status: item.status,
        count: Number(item.count || 0),
        time: item.time || ''
      }))
      return
    }
  } catch {
    // 页面保持空状态，避免展示不真实的模拟数据。
  }
  syncLogs.value = []
}

async function loadAdminReviews() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/reviews')
    const payload = await response.json()
    if (payload.code === '200' && Array.isArray(payload.data)) {
      adminReviews.value = payload.data.map((item: ReviewRow) => ({
        id: Number(item.id),
        platform: item.platform,
        orderNo: item.orderNo,
        merchantName: item.merchantName,
        productName: item.productName,
        productScore: Number(item.productScore || 0),
        serviceScore: Number(item.serviceScore || 0),
        score: Number(item.score || 0),
        content: item.content || '',
        sentiment: item.sentiment || '中性',
        riskLevel: item.riskLevel || '低风险',
        keywords: item.keywords || '',
        analysisSummary: item.analysisSummary || '',
        suggestion: item.suggestion || '',
        reviewedAt: item.reviewedAt || '',
        disputeId: item.disputeId ? Number(item.disputeId) : null,
        disputeStatus: item.disputeStatus || '',
        disputeReason: item.disputeReason || '',
        disputeAdminNote: item.disputeAdminNote || '',
        disputeCreatedAt: item.disputeCreatedAt || ''
      }))
      return
    }
  } catch {
    // 页面保持空状态，避免展示不真实的模拟数据。
  }
  adminReviews.value = []
}

async function loadAdminRules() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/rules')
    const payload = await response.json()
    if (payload.code === '200' && Array.isArray(payload.data)) {
      adminRules.value = payload.data.map((item: RuleRow) => ({
        id: Number(item.id),
        ruleName: item.ruleName,
        ruleType: item.ruleType,
        ruleTypeText: item.ruleTypeText,
        conditionsJson: item.conditionsJson || '{}',
        conditionsText: item.conditionsText || item.conditionsJson || '',
        actionJson: item.actionJson || '{}',
        actionText: item.actionText || item.actionJson || '',
        content: item.content || '',
        enabled: Boolean(item.enabled),
        updatedAt: item.updatedAt || ''
      }))
      return
    }
  } catch {
    // 页面保持空状态，避免展示不真实的模拟数据。
  }
  adminRules.value = []
}

async function loadKnowledge() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/knowledge')
    const payload = await response.json()
    if (payload.code === '200' && payload.data) {
      knowledgeArticles.value = (payload.data.articles || []).map((item: KnowledgeArticleRow) => ({
        id: Number(item.id),
        title: item.title || '',
        content: item.content || '',
        category: item.category || 'PLATFORM_POLICY',
        categoryText: item.categoryText || '',
        tagsJson: item.tagsJson || '[]',
        status: item.status || 'DRAFT',
        statusText: item.statusText || '',
        updatedAt: item.updatedAt || ''
      }))
      faqItems.value = (payload.data.faqs || []).map((item: FaqRow) => ({
        id: Number(item.id),
        question: item.question || '',
        answer: item.answer || '',
        category: item.category || 'AFTER_SALE',
        categoryText: item.categoryText || '',
        priority: Number(item.priority || 0),
        enabled: Boolean(item.enabled),
        updatedAt: item.updatedAt || ''
      }))
      return
    }
  } catch {
    // 页面保持空状态，避免展示不真实的模拟数据。
  }
  knowledgeArticles.value = []
  faqItems.value = []
}

function openArticleEditor(row?: KnowledgeArticleRow) {
  articleForm.value = row
    ? { ...row }
    : {
        id: 0,
        title: '',
        content: '',
        category: 'PLATFORM_POLICY',
        categoryText: '平台政策',
        tagsJson: '[]',
        status: 'PUBLISHED',
        statusText: '已发布',
        updatedAt: ''
      }
  articleEditorVisible.value = true
}

function openFaqEditor(row?: FaqRow) {
  faqForm.value = row
    ? { ...row }
    : {
        id: 0,
        question: '',
        answer: '',
        category: 'AFTER_SALE',
        categoryText: '售后问题',
        priority: 0,
        enabled: true,
        updatedAt: ''
      }
  faqEditorVisible.value = true
}

async function saveArticle() {
  if (!articleForm.value.title.trim() || !articleForm.value.content.trim()) {
    ElMessage.warning('请填写标题和内容')
    return
  }
  savingKnowledge.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/knowledge/articles', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: articleForm.value.id || null,
        title: articleForm.value.title,
        content: articleForm.value.content,
        category: articleForm.value.category,
        tagsJson: articleForm.value.tagsJson,
        status: articleForm.value.status
      })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '保存失败')
    }
    ElMessage.success('知识文章已保存')
    articleEditorVisible.value = false
    await loadKnowledge()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '保存知识文章失败')
  } finally {
    savingKnowledge.value = false
  }
}

async function saveFaq() {
  if (!faqForm.value.question.trim() || !faqForm.value.answer.trim()) {
    ElMessage.warning('请填写问题和答案')
    return
  }
  savingKnowledge.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/knowledge/faqs', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: faqForm.value.id || null,
        question: faqForm.value.question,
        answer: faqForm.value.answer,
        category: faqForm.value.category,
        priority: faqForm.value.priority,
        enabled: faqForm.value.enabled
      })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '保存失败')
    }
    ElMessage.success('常见问题已保存')
    faqEditorVisible.value = false
    await loadKnowledge()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '保存常见问题失败')
  } finally {
    savingKnowledge.value = false
  }
}

async function toggleFaq(row: FaqRow) {
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/admin/knowledge/faqs/${row.id}/toggle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ enabled: row.enabled })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '状态更新失败')
    }
    ElMessage.success(row.enabled ? 'FAQ 已启用' : 'FAQ 已停用')
  } catch (error) {
    row.enabled = !row.enabled
    ElMessage.error(error instanceof Error ? error.message : 'FAQ 状态更新失败')
  }
}

async function deleteArticle(row: KnowledgeArticleRow) {
  if (!(await confirmDanger(`确认删除知识文章“${row.title}”吗？`))) {
    return
  }
  await deleteKnowledgeItem(`http://localhost:8080/api/twenty-mall/admin/knowledge/articles/${row.id}/delete`, '知识文章已删除')
}

async function deleteFaq(row: FaqRow) {
  if (!(await confirmDanger(`确认删除常见问题“${row.question}”吗？`))) {
    return
  }
  await deleteKnowledgeItem(`http://localhost:8080/api/twenty-mall/admin/knowledge/faqs/${row.id}/delete`, '常见问题已删除')
}

async function deleteKnowledgeItem(url: string, successText: string) {
  try {
    const response = await fetch(url, { method: 'POST' })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '删除失败')
    }
    ElMessage.success(successText)
    await loadKnowledge()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '删除失败')
  }
}

async function confirmDanger(message: string) {
  try {
    await ElMessageBox.confirm(message, '删除确认', {
      confirmButtonText: '确认删除',
      cancelButtonText: '取消',
      type: 'warning'
    })
    return true
  } catch {
    return false
  }
}

function openRuleEditor(row?: RuleRow) {
  ruleForm.value = row
    ? { ...row }
    : {
        id: 0,
        ruleName: '',
        ruleType: 'RETURN_POLICY',
        ruleTypeText: '退货政策',
        conditionsJson: '{}',
        conditionsText: '无特殊触发条件',
        actionJson: '{}',
        actionText: '记录规则命中结果',
        content: '',
        enabled: true,
        updatedAt: ''
      }
  ruleEditorVisible.value = true
}

async function saveRule() {
  if (!ruleForm.value.ruleName.trim()) {
    ElMessage.warning('请输入规则名称')
    return
  }
  savingRule.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/rules', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        id: ruleForm.value.id || null,
        ruleName: ruleForm.value.ruleName,
        ruleType: ruleForm.value.ruleType,
        conditionsJson: ruleForm.value.conditionsJson,
        actionJson: ruleForm.value.actionJson,
        content: ruleForm.value.content,
        enabled: ruleForm.value.enabled
      })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '保存失败')
    }
    ElMessage.success('规则已保存')
    ruleEditorVisible.value = false
    await loadAdminRules()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '保存规则失败')
  } finally {
    savingRule.value = false
  }
}

async function toggleRule(row: RuleRow) {
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/admin/rules/${row.id}/toggle`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ enabled: row.enabled })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '状态更新失败')
    }
    ElMessage.success(row.enabled ? '规则已启用' : '规则已停用')
  } catch (error) {
    row.enabled = !row.enabled
    ElMessage.error(error instanceof Error ? error.message : '规则状态更新失败')
  }
}

async function deleteRule(row: RuleRow) {
  try {
    await ElMessageBox.confirm(
      `确认删除规则“${row.ruleName}”吗？删除后不会再参与售后处理判断。`,
      '删除规则确认',
      {
        confirmButtonText: '确认删除',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
  } catch {
    return
  }
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/admin/rules/${row.id}/delete`, {
      method: 'POST'
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '删除失败')
    }
    ElMessage.success('规则已删除')
    await loadAdminRules()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '删除规则失败')
  }
}

async function deleteSelectedReview() {
  if (!selectedReview.value) {
    return
  }
  const review = selectedReview.value
  try {
    await ElMessageBox.confirm(
      `确认删除订单 ${review.orderNo} 的这条评价吗？删除后评价分析、商家端评价列表中都不会再展示该评价。`,
      '删除评价确认',
      {
        confirmButtonText: '确认删除',
        cancelButtonText: '取消',
        type: 'warning'
      }
    )
  } catch {
    return
  }
  deletingReview.value = true
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/admin/reviews/${review.id}/delete`, {
      method: 'POST'
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '删除失败')
    }
    ElMessage.success('评价已删除')
    selectedReview.value = null
    await loadAdminReviews()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '删除评价失败')
  } finally {
    deletingReview.value = false
  }
}

async function reviewSelectedDispute(result: 'APPROVE' | 'REJECT') {
  if (!selectedReview.value?.disputeId) {
    ElMessage.warning('当前评价没有待审核的异议')
    return
  }
  const review = selectedReview.value
  const isApprove = result === 'APPROVE'
  let adminNote = ''
  try {
    const promptResult = await ElMessageBox.prompt(
      isApprove
        ? `确认通过订单 ${review.orderNo} 的评价异议，并删除该评价吗？请填写审核说明。`
        : `确认拒绝订单 ${review.orderNo} 的评价异议吗？请填写拒绝原因。`,
      isApprove ? '通过评价异议' : '拒绝评价异议',
      {
        confirmButtonText: isApprove ? '通过并删除' : '确认拒绝',
        cancelButtonText: '取消',
        inputType: 'textarea',
        inputPlaceholder: isApprove ? '例如：经核实评价内容与订单事实不符，予以删除。' : '例如：评价内容属于用户真实体验，暂不删除。',
        inputValidator: (value) => Boolean(value && value.trim()) || '请填写审核说明'
      }
    )
    adminNote = promptResult.value.trim()
  } catch {
    return
  }
  reviewingDispute.value = true
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/admin/reviews/disputes/${review.disputeId}/review`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ result, adminNote })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '审核失败')
    }
    ElMessage.success(isApprove ? '异议已通过，评价已删除' : '异议已拒绝，评价保留')
    selectedReview.value = null
    await loadAdminReviews()
    await loadOverview()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '评价异议审核失败')
  } finally {
    reviewingDispute.value = false
  }
}

function formatNumber(value: number) {
  return value.toLocaleString('zh-CN')
}

function formatLocalDateTime(value: Date) {
  return `${value.getFullYear()}.${value.getMonth() + 1}.${value.getDate()} ${String(value.getHours()).padStart(2, '0')}:${String(value.getMinutes()).padStart(2, '0')}:${String(value.getSeconds()).padStart(2, '0')}`
}

function providerText(provider: string) {
  const map: Record<string, string> = {
    deepseek: 'DeepSeek',
    qwen: '通义千问',
    glm: '智谱 GLM',
    openai: 'OpenAI'
  }
  return map[provider] || provider || '暂无数据'
}

function countUniqueBoundShops(platformName: string) {
  const accountNos = merchantBindings.value
    .filter((item) => item.platformName === platformName && item.bindStatus === '已绑定')
    .map((item) => item.secondaryAccountNo)
  return new Set(accountNos).size
}

function countUniquePrimary(rows: BindingRow[]) {
  return new Set(rows.map((item) => item.primaryAccountNo).filter(Boolean)).size
}

function activityTagType(module: string) {
  if (module === '评价分析') {
    return 'warning'
  }
  if (module === '规则配置') {
    return 'primary'
  }
  if (module === '知识库') {
    return 'success'
  }
  return 'info'
}

function avatarText(name?: string, accountNo?: string) {
  return (name || accountNo || '账').slice(0, 1)
}

function sentimentTagType(sentiment: string) {
  if (sentiment === '正向') {
    return 'success'
  }
  if (sentiment === '负向') {
    return 'danger'
  }
  return 'info'
}

function riskTagType(riskLevel: string) {
  if (riskLevel === '高风险') {
    return 'danger'
  }
  if (riskLevel === '中风险') {
    return 'warning'
  }
  return 'success'
}

function disputeTagType(status?: string) {
  if (status === '待审核') {
    return 'warning'
  }
  if (status === '已通过') {
    return 'success'
  }
  if (status === '已拒绝') {
    return 'danger'
  }
  return 'info'
}

function shouldShowPrimaryCell(rows: BindingRow[], row: BindingRow, index: number) {
  if (index <= 0) {
    return true
  }
  const previous = rows[index - 1]
  return !previous || previous.primaryAccountNo !== row.primaryAccountNo
}
</script>

<style scoped>
.overview-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.overview-metrics {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.metric-card {
  min-height: 112px;
}

.metric-label {
  color: #475569;
  font-size: 14px;
  font-weight: 700;
}

.metric-card strong {
  margin-top: 8px;
  color: #0f172a;
  font-size: 32px;
  line-height: 1;
}

.metric-card p {
  margin: 10px 0 0;
  color: #64748b;
  font-size: 13px;
}

.overview-row {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.overview-row.wide-left {
  grid-template-columns: minmax(0, 1.55fr) minmax(360px, 0.95fr);
}

.overview-panel {
  min-height: 220px;
}

.panel-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 14px;
}

.panel-title h2 {
  margin: 0;
  color: #0f172a;
  font-size: 18px;
}

.panel-subtitle {
  color: #64748b;
  font-size: 13px;
}

.todo-list,
.sync-list,
.activity-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.todo-item,
.sync-item,
.activity-item {
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.todo-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px;
}

.todo-item strong {
  display: inline-block;
  min-width: 42px;
  margin: 0 10px 0 0;
  color: #0f172a;
  font-size: 22px;
}

.todo-item span {
  color: #334155;
  font-size: 14px;
}

.sync-item {
  padding: 12px 14px;
}

.sync-main,
.sync-sub {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.sync-main span {
  color: #0f172a;
  font-weight: 700;
}

.sync-main strong {
  margin: 0;
  color: #1d4ed8;
  font-size: 20px;
}

.sync-sub {
  margin-top: 8px;
  color: #64748b;
  font-size: 13px;
}

.trend-chart {
  display: grid;
  grid-template-columns: repeat(7, minmax(0, 1fr));
  align-items: end;
  height: 230px;
  padding: 8px 0 0;
  border-bottom: 1px solid #e5e7eb;
}

.trend-column {
  display: flex;
  min-width: 0;
  height: 100%;
  flex-direction: column;
  align-items: center;
  justify-content: flex-end;
  gap: 8px;
}

.trend-bars {
  display: flex;
  align-items: flex-end;
  justify-content: center;
  gap: 5px;
  width: 100%;
  height: 170px;
}

.trend-bar {
  width: 10px;
  min-height: 8px;
  border-radius: 6px 6px 0 0;
}

.trend-bar.order,
.legend-dot.order {
  background: #2563eb;
}

.trend-bar.after-sale,
.legend-dot.after-sale {
  background: #f97316;
}

.trend-bar.review,
.legend-dot.review {
  background: #16a34a;
}

.trend-date {
  color: #64748b;
  font-size: 12px;
}

.chart-legend {
  display: flex;
  gap: 18px;
  margin-top: 12px;
  color: #475569;
  font-size: 13px;
}

.legend-dot {
  display: inline-block;
  width: 9px;
  height: 9px;
  margin-right: 6px;
  border-radius: 50%;
}

.binding-summary {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin-bottom: 14px;
}

.binding-item {
  padding: 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.binding-item span {
  display: block;
  color: #64748b;
  font-size: 13px;
}

.binding-item strong {
  margin-top: 6px;
  color: #0f172a;
  font-size: 24px;
}

.platform-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.platform-mini-icon {
  width: 26px;
  height: 26px;
  border-radius: 6px;
  object-fit: cover;
  background: #eef2f7;
}

.activity-item {
  display: grid;
  grid-template-columns: 92px minmax(0, 1fr) 150px;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
}

.activity-item strong {
  margin: 0;
  color: #0f172a;
  font-size: 14px;
}

.activity-item p {
  margin: 4px 0 0;
  overflow: hidden;
  color: #64748b;
  font-size: 13px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.activity-item > span {
  color: #64748b;
  font-size: 13px;
  text-align: right;
}

.review-page,
.knowledge-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.review-stats,
.rule-stats,
.knowledge-stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.review-stat,
.rule-stat,
.knowledge-stat {
  min-height: 96px;
}

.review-stat span,
.rule-stat span,
.knowledge-stat span {
  color: #64748b;
  font-size: 14px;
}

.review-stat strong,
.rule-stat strong,
.knowledge-stat strong {
  display: block;
  margin-top: 12px;
  color: #0f172a;
  font-size: 28px;
}

.rule-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.ai-config-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 16px;
}

.card-toolbar h2 {
  margin: 0;
  color: #0f172a;
  font-size: 20px;
}
</style>
