<template>
  <div v-if="!currentAdmin" class="admin-login-page">
    <section class="admin-login-brand">
      <div class="admin-login-logo">
        <img :src="adminBrandIcon" alt="" />
      </div>
      <span class="admin-login-kicker">FUSION AFTER-SALE GOVERNANCE</span>
      <h1>平台管理后台</h1>
      <p>面向多平台订单、售后、评价与争议流程的统一运营管理中心。</p>
      <div class="admin-login-features">
        <div>
          <strong>账号治理</strong>
          <span>统一维护一级账号与平台绑定关系</span>
        </div>
        <div>
          <strong>风险审核</strong>
          <span>集中处理评价异议与售后争议</span>
        </div>
        <div>
          <strong>AI 配置</strong>
          <span>管理客服问答与评价分析调用能力</span>
        </div>
      </div>
    </section>
    <section class="admin-login-card">
      <div class="admin-login-head">
        <span>ADMIN LOGIN</span>
        <h2>管理员秘钥登录</h2>
        <p>当前系统已配置 4 个管理员身份</p>
      </div>
      <el-form class="admin-login-form" label-position="top" @submit.prevent>
        <el-form-item label="选择管理员">
          <div class="admin-selector">
            <button
              v-for="admin in adminAccounts"
              :key="admin.id"
              type="button"
              :class="{ active: selectedAdminId === admin.id }"
              @click="selectLoginAdmin(admin.id)"
            >
              <img :src="admin.avatar" :alt="admin.name" />
              <strong>{{ admin.name }}</strong>
            </button>
          </div>
        </el-form-item>
        <el-form-item label="管理员秘钥">
          <el-input
            v-model="adminLoginKey"
            size="large"
            show-password
            @keyup.enter="loginAdmin"
          />
        </el-form-item>
        <el-button class="admin-login-submit" type="primary" size="large" :loading="adminLoginLoading" @click="loginAdmin">
          登录管理员端
        </el-button>
      </el-form>
      <div class="admin-login-modules">
        <strong>管理员端核心处理</strong>
        <div>
          <span>争议订单裁决</span>
          <span>评价异议审核</span>
          <span>账号封禁解封</span>
          <span>规则与知识库配置</span>
        </div>
      </div>
    </section>
  </div>
  <el-container v-else class="shell">
    <el-aside width="230px" class="aside">
      <div class="brand">
        <img class="brand-logo" :src="adminBrandIcon" alt="" />
        <div>
          <strong>平台管理后台</strong>
          <span>融合电商治理中心</span>
        </div>
      </div>
      <nav class="admin-nav">
        <button v-for="item in sections" :key="item.label" :class="{ active: active === item.label }" @click="active = item.label">
          <span class="nav-symbol">{{ item.icon }}</span>
          <span>{{ item.label }}</span>
        </button>
      </nav>
    </el-aside>
    <el-container>
      <el-header class="header">
        <h1>{{ active }}</h1>
        <div class="header-actions">
          <el-tag type="success">系统运行中</el-tag>
          <div class="admin-session">
            <img v-if="currentAdminAvatar" :src="currentAdminAvatar" alt="" />
            <span>{{ currentAdmin.name }}</span>
            <el-button size="small" plain @click="logoutAdmin">退出登录</el-button>
          </div>
        </div>
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
        <section v-else-if="active === '外部平台'" class="external-platform-page">
          <div class="platform-overview-grid">
            <div v-for="item in platformMetrics" :key="item.label" class="card platform-overview-card">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="platform-card-grid">
            <div v-for="item in platforms" :key="item.code" class="card platform-access-card">
              <div class="platform-access-head">
                <img class="platform-large-icon" :src="item.icon" :alt="item.name" />
                <div>
                  <strong>{{ item.name }}</strong>
                  <span>{{ item.code }}</span>
                </div>
                <el-tag :type="platformStatusTagType(item.status)">{{ item.status }}</el-tag>
              </div>
              <p>{{ item.description }}</p>
              <div class="platform-access-meta">
                <div>
                  <span>绑定店铺</span>
                  <strong>{{ item.shops }}</strong>
                </div>
                <div>
                  <span>接入类型</span>
                  <strong>{{ isSelfBuiltPlatform(item.code) ? '自建数据库' : '开放平台' }}</strong>
                </div>
              </div>
              <div class="platform-access-footer">
                <span>{{ platformStatusDescription(item.status) }}</span>
                <el-button :type="item.status === '启用' ? 'primary' : 'info'" plain @click="selectedPlatform = item">查看配置</el-button>
              </div>
            </div>
          </div>
          <el-dialog v-model="platformDetailVisible" title="平台接入配置" width="680px">
            <template v-if="selectedPlatform">
              <div class="platform-dialog-head">
                <img class="platform-large-icon" :src="selectedPlatform.icon" :alt="selectedPlatform.name" />
                <div>
                  <strong>{{ selectedPlatform.name }}</strong>
                  <span>{{ selectedPlatform.code }}</span>
                </div>
                <el-tag :type="platformStatusTagType(selectedPlatform.status)">{{ selectedPlatform.status }}</el-tag>
              </div>
              <div class="platform-config-grid">
                <div>
                  <span>接入类型</span>
                  <strong>{{ isSelfBuiltPlatform(selectedPlatform.code) ? '自建数据库' : '开放平台' }}</strong>
                </div>
                <div>
                  <span>绑定店铺数</span>
                  <strong>{{ selectedPlatform.shops }}</strong>
                </div>
                <div>
                  <span>当前状态</span>
                  <strong>{{ selectedPlatform.status }}</strong>
                </div>
                <div>
                  <span>数据范围</span>
                  <strong>{{ isSelfBuiltPlatform(selectedPlatform.code) ? '订单、售后、评价' : '待开放平台授权' }}</strong>
                </div>
              </div>
              <div class="platform-config-section">
                <h3>平台说明</h3>
                <p>{{ selectedPlatform.description }}</p>
              </div>
              <div class="platform-config-section">
                <h3>接入状态说明</h3>
                <p>{{ platformStatusDescription(selectedPlatform.status) }}</p>
              </div>
              <div class="platform-config-section">
                <h3>后续处理建议</h3>
                <p>{{ platformNextStep(selectedPlatform) }}</p>
              </div>
            </template>
            <template #footer>
              <el-button type="primary" @click="platformDetailVisible = false">知道了</el-button>
            </template>
          </el-dialog>
        </section>
        <section v-else-if="active === '同步监控'" class="sync-monitor-page">
          <div class="sync-metric-grid">
            <div v-for="item in syncMetrics" :key="item.label" class="card sync-metric-card">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="sync-card-grid">
            <div v-for="item in syncOverview" :key="item.task" class="card sync-task-card">
              <div class="sync-task-head">
                <div>
                  <strong>{{ item.task }}</strong>
                  <span>{{ item.time || '暂无同步时间' }}</span>
                </div>
                <el-tag :type="item.status === '正常' ? 'success' : 'info'">{{ item.status }}</el-tag>
              </div>
              <div class="sync-task-value">
                <span>同步数量</span>
                <strong>{{ formatNumber(item.count) }}</strong>
              </div>
              <el-progress :percentage="syncProgress(item.count)" :status="item.status === '正常' ? 'success' : undefined" />
              <div class="sync-task-footer">
                <span>{{ syncTaskDescription(item.task, item.count) }}</span>
                <el-button plain @click="selectedSyncLog = item">查看详情</el-button>
              </div>
            </div>
          </div>
          <div class="card sync-detail-panel">
            <div class="panel-title">
              <h2>同步记录明细</h2>
              <span class="panel-subtitle">读取后端数据库统计结果</span>
            </div>
            <el-table :data="syncLogs">
              <el-table-column prop="task" label="任务" min-width="220" />
              <el-table-column prop="status" label="状态" width="120">
                <template #default="{ row }">
                  <el-tag :type="row.status === '正常' ? 'success' : 'info'">{{ row.status }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column prop="count" label="数量" width="140" />
              <el-table-column prop="time" label="时间" min-width="180" />
            </el-table>
          </div>
          <el-dialog v-model="syncDetailVisible" title="同步任务详情" width="560px">
            <template v-if="selectedSyncLog">
              <div class="sync-dialog-title">
                <strong>{{ selectedSyncLog.task }}</strong>
                <el-tag :type="selectedSyncLog.status === '正常' ? 'success' : 'info'">{{ selectedSyncLog.status }}</el-tag>
              </div>
              <div class="platform-config-grid">
                <div>
                  <span>同步数量</span>
                  <strong>{{ formatNumber(selectedSyncLog.count) }}</strong>
                </div>
                <div>
                  <span>同步时间</span>
                  <strong>{{ selectedSyncLog.time || '暂无时间' }}</strong>
                </div>
                <div>
                  <span>数据来源</span>
                  <strong>万象商城数据库</strong>
                </div>
                <div>
                  <span>同步结果</span>
                  <strong>{{ selectedSyncLog.status }}</strong>
                </div>
              </div>
              <div class="platform-config-section">
                <h3>任务说明</h3>
                <p>{{ syncTaskDescription(selectedSyncLog.task, selectedSyncLog.count) }}</p>
              </div>
            </template>
            <template #footer>
              <el-button type="primary" @click="syncDetailVisible = false">知道了</el-button>
            </template>
          </el-dialog>
        </section>
        <section v-else-if="active === '消费者管理'" class="user-management-page">
          <div class="user-metrics">
            <div v-for="item in consumerBindingMetrics" :key="item.label" class="card user-metric">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="card user-filter-card">
            <el-input v-model="consumerBindingKeyword" clearable placeholder="搜索一级账号、昵称、二级账号或店铺名称" />
            <el-select v-model="consumerBindingPlatformFilter" placeholder="绑定平台">
              <el-option label="全部平台" value="ALL" />
              <el-option v-for="item in consumerBindingPlatformOptions" :key="item" :label="item" :value="item" />
            </el-select>
          </div>
          <div class="user-group-list">
            <div v-for="group in filteredConsumerBindingGroups" :key="group.primaryAccountNo" class="card user-group-card">
              <div class="user-group-head">
                <div class="user-profile-cell">
                  <el-avatar v-if="group.primaryAvatar" :size="48" :src="group.primaryAvatar" />
                  <el-avatar v-else :size="48">{{ avatarText(group.primaryDisplayName, group.primaryAccountNo) }}</el-avatar>
                  <div>
                    <strong>{{ group.primaryDisplayName || '未设置昵称' }}</strong>
                    <span>{{ group.primaryAccountNo }}</span>
                  </div>
                </div>
                <div class="user-group-meta">
                  <el-tag :type="group.primaryBanStatus === '已封禁' ? 'danger' : 'success'">
                    {{ group.primaryBanStatus || '正常' }}
                  </el-tag>
                  <el-tag type="primary">{{ group.bindings.length }} 个绑定账号</el-tag>
                  <el-button
                    :type="group.primaryBanStatus === '已封禁' ? 'success' : 'danger'"
                    plain
                    @click="group.primaryBanStatus === '已封禁' ? unbanPrimaryAccount(group, 'CONSUMER') : openBanDialog(group, 'CONSUMER')"
                  >
                    {{ group.primaryBanStatus === '已封禁' ? '解除封禁' : '封禁账号' }}
                  </el-button>
                  <el-button type="primary" plain @click="selectedConsumerBindingGroup = group">查看详情</el-button>
                </div>
              </div>
              <div class="binding-row-list">
                <div v-for="binding in group.bindings" :key="`${binding.platformName}-${binding.secondaryAccountNo}`" class="binding-row-card">
                  <div class="platform-cell">
                    <img class="platform-mini-icon" :src="platformIconByName(binding.platformName)" :alt="binding.platformName" />
                    <span>{{ binding.platformName }}</span>
                  </div>
                  <div>
                    <span class="binding-label">二级账号</span>
                    <strong>{{ binding.secondaryAccountNo }}</strong>
                  </div>
                  <div>
                    <span class="binding-label">账号名称</span>
                    <strong>{{ binding.secondaryDisplayName || '未设置名称' }}</strong>
                  </div>
                  <div>
                    <span class="binding-label">绑定时间</span>
                    <strong>{{ binding.boundAt || '暂无时间' }}</strong>
                  </div>
                </div>
              </div>
            </div>
            <el-empty v-if="filteredConsumerBindingGroups.length === 0" description="暂无符合条件的用户绑定数据" />
          </div>
          <el-dialog v-model="consumerBindingDetailVisible" title="用户绑定详情" width="760px">
            <template v-if="selectedConsumerBindingGroup">
              <div class="dialog-user-head">
                <el-avatar v-if="selectedConsumerBindingGroup.primaryAvatar" :size="56" :src="selectedConsumerBindingGroup.primaryAvatar" />
                <el-avatar v-else :size="56">{{ avatarText(selectedConsumerBindingGroup.primaryDisplayName, selectedConsumerBindingGroup.primaryAccountNo) }}</el-avatar>
                <div>
                  <strong>{{ selectedConsumerBindingGroup.primaryDisplayName || '未设置昵称' }}</strong>
                  <span>一级账号：{{ selectedConsumerBindingGroup.primaryAccountNo }}</span>
                  <span>账号状态：{{ selectedConsumerBindingGroup.primaryBanStatus || '正常' }}{{ selectedConsumerBindingGroup.primaryBanUntil ? `（${selectedConsumerBindingGroup.primaryBanUntil}）` : '' }}</span>
                </div>
                <div class="dialog-account-actions">
                  <el-button
                    :type="selectedConsumerBindingGroup.primaryBanStatus === '已封禁' ? 'success' : 'danger'"
                    plain
                    @click="selectedConsumerBindingGroup.primaryBanStatus === '已封禁' ? unbanPrimaryAccount(selectedConsumerBindingGroup, 'CONSUMER') : openBanDialog(selectedConsumerBindingGroup, 'CONSUMER')"
                  >
                    {{ selectedConsumerBindingGroup.primaryBanStatus === '已封禁' ? '解除封禁' : '封禁账号' }}
                  </el-button>
                </div>
              </div>
              <el-table :data="selectedConsumerBindingGroup.bindings" border>
                <el-table-column label="绑定平台" width="140">
                  <template #default="{ row }">
                    <div class="platform-cell">
                      <img class="platform-mini-icon" :src="platformIconByName(row.platformName)" :alt="row.platformName" />
                      <span>{{ row.platformName }}</span>
                    </div>
                  </template>
                </el-table-column>
                <el-table-column prop="secondaryAccountNo" label="二级平台账号" min-width="150" />
                <el-table-column prop="secondaryDisplayName" label="二级账号名称" min-width="180" />
                <el-table-column prop="boundAt" label="绑定时间" min-width="170" />
              </el-table>
            </template>
          </el-dialog>
        </section>
        <section v-else-if="active === '商家管理'" class="user-management-page">
          <div class="user-metrics">
            <div v-for="item in merchantBindingMetrics" :key="item.label" class="card user-metric">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="card user-filter-card">
            <el-input v-model="merchantBindingKeyword" clearable placeholder="搜索一级商家账号、昵称、店铺账号或店铺名称" />
            <el-select v-model="merchantBindingPlatformFilter" placeholder="绑定平台">
              <el-option label="全部平台" value="ALL" />
              <el-option v-for="item in merchantBindingPlatformOptions" :key="item" :label="item" :value="item" />
            </el-select>
          </div>
          <div class="user-group-list">
            <div v-for="group in filteredMerchantBindingGroups" :key="group.primaryAccountNo" class="card user-group-card">
              <div class="user-group-head">
                <div class="user-profile-cell">
                  <el-avatar v-if="group.primaryAvatar" :size="48" :src="group.primaryAvatar" />
                  <el-avatar v-else :size="48">{{ avatarText(group.primaryDisplayName, group.primaryAccountNo) }}</el-avatar>
                  <div>
                    <strong>{{ group.primaryDisplayName || '未设置名称' }}</strong>
                    <span>{{ group.primaryAccountNo }}</span>
                  </div>
                </div>
                <div class="user-group-meta">
                  <el-tag :type="group.primaryBanStatus === '已封禁' ? 'danger' : 'success'">
                    {{ group.primaryBanStatus || '正常' }}
                  </el-tag>
                  <el-tag type="success">{{ group.bindings.length }} 个绑定店铺</el-tag>
                  <el-button
                    :type="group.primaryBanStatus === '已封禁' ? 'success' : 'danger'"
                    plain
                    @click="group.primaryBanStatus === '已封禁' ? unbanPrimaryAccount(group, 'MERCHANT') : openBanDialog(group, 'MERCHANT')"
                  >
                    {{ group.primaryBanStatus === '已封禁' ? '解除封禁' : '封禁账号' }}
                  </el-button>
                  <el-button type="primary" plain @click="selectedMerchantBindingGroup = group">查看详情</el-button>
                </div>
              </div>
              <div class="binding-row-list">
                <div v-for="binding in group.bindings" :key="`${binding.platformName}-${binding.secondaryAccountNo}`" class="binding-row-card merchant-binding-card">
                  <div class="platform-cell">
                    <img class="platform-mini-icon" :src="platformIconByName(binding.platformName)" :alt="binding.platformName" />
                    <span>{{ binding.platformName }}</span>
                  </div>
                  <div>
                    <span class="binding-label">店铺账号</span>
                    <strong>{{ binding.secondaryAccountNo }}</strong>
                  </div>
                  <div>
                    <span class="binding-label">店铺名称</span>
                    <strong>{{ binding.secondaryDisplayName || '未设置店铺名称' }}</strong>
                  </div>
                  <div>
                    <span class="binding-label">绑定时间</span>
                    <strong>{{ binding.boundAt || '暂无时间' }}</strong>
                  </div>
                </div>
                <div v-if="group.bindings.length === 0" class="binding-empty-row">暂无绑定店铺</div>
              </div>
            </div>
            <el-empty v-if="filteredMerchantBindingGroups.length === 0" description="暂无符合条件的商家绑定数据" />
          </div>
          <el-dialog v-model="merchantBindingDetailVisible" title="商家绑定详情" width="760px">
            <template v-if="selectedMerchantBindingGroup">
              <div class="dialog-user-head">
                <el-avatar v-if="selectedMerchantBindingGroup.primaryAvatar" :size="56" :src="selectedMerchantBindingGroup.primaryAvatar" />
                <el-avatar v-else :size="56">{{ avatarText(selectedMerchantBindingGroup.primaryDisplayName, selectedMerchantBindingGroup.primaryAccountNo) }}</el-avatar>
                <div>
                  <strong>{{ selectedMerchantBindingGroup.primaryDisplayName || '未设置名称' }}</strong>
                  <span>一级商家账号：{{ selectedMerchantBindingGroup.primaryAccountNo }}</span>
                  <span>账号状态：{{ selectedMerchantBindingGroup.primaryBanStatus || '正常' }}{{ selectedMerchantBindingGroup.primaryBanUntil ? `（${selectedMerchantBindingGroup.primaryBanUntil}）` : '' }}</span>
                </div>
                <div class="dialog-account-actions">
                  <el-button
                    :type="selectedMerchantBindingGroup.primaryBanStatus === '已封禁' ? 'success' : 'danger'"
                    plain
                    @click="selectedMerchantBindingGroup.primaryBanStatus === '已封禁' ? unbanPrimaryAccount(selectedMerchantBindingGroup, 'MERCHANT') : openBanDialog(selectedMerchantBindingGroup, 'MERCHANT')"
                  >
                    {{ selectedMerchantBindingGroup.primaryBanStatus === '已封禁' ? '解除封禁' : '封禁账号' }}
                  </el-button>
                </div>
              </div>
              <el-table v-if="selectedMerchantBindingGroup.bindings.length" :data="selectedMerchantBindingGroup.bindings" border>
                <el-table-column label="绑定平台" width="140">
                  <template #default="{ row }">
                    <div class="platform-cell">
                      <img class="platform-mini-icon" :src="platformIconByName(row.platformName)" :alt="row.platformName" />
                      <span>{{ row.platformName }}</span>
                    </div>
                  </template>
                </el-table-column>
                <el-table-column prop="secondaryAccountNo" label="店铺账号" min-width="150" />
                <el-table-column prop="secondaryDisplayName" label="店铺名称" min-width="200" />
                <el-table-column prop="boundAt" label="绑定时间" min-width="170" />
              </el-table>
              <el-empty v-else description="该一级商家账号暂无绑定店铺" />
            </template>
          </el-dialog>
        </section>
        <section v-else-if="active === '知识库'" class="knowledge-page">
          <div class="knowledge-stats">
            <div v-for="item in knowledgeMetrics" :key="item.label" class="card knowledge-stat">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="card knowledge-workbench">
            <div class="knowledge-head">
              <div>
                <h2>知识库管理</h2>
                <p>维护客服回答、售后规则解释和平台政策说明，供 AI 客服与人工客服协同使用。</p>
              </div>
              <div>
                <el-button @click="openFaqEditor()">新增常见问题</el-button>
                <el-button type="primary" @click="openArticleEditor()">新增知识文章</el-button>
              </div>
            </div>
            <div class="knowledge-filter-bar">
              <el-input v-model="knowledgeKeyword" clearable placeholder="搜索标题、问题、标签或内容摘要" />
              <el-select v-model="knowledgeCategoryFilter" placeholder="全部分类">
                <el-option label="全部分类" value="ALL" />
                <el-option v-for="item in knowledgeCategoryOptions" :key="item" :label="item" :value="item" />
              </el-select>
            </div>
            <el-tabs v-model="knowledgeTab">
              <el-tab-pane label="知识文章" name="articles">
                <div class="knowledge-card-list">
                  <div v-for="row in filteredKnowledgeArticles" :key="row.id" class="knowledge-item-card">
                    <div class="knowledge-item-main">
                      <div class="knowledge-item-title">
                        <strong>{{ row.title }}</strong>
                        <el-tag :type="row.status === 'PUBLISHED' ? 'success' : 'info'">{{ row.statusText }}</el-tag>
                      </div>
                      <p>{{ row.content }}</p>
                      <div class="knowledge-tags">
                        <el-tag effect="light">{{ row.categoryText }}</el-tag>
                        <el-tag v-for="tag in parseTags(row.tagsJson)" :key="tag" type="info" effect="plain">{{ tag }}</el-tag>
                      </div>
                    </div>
                    <div class="knowledge-item-side">
                      <span>更新时间</span>
                      <strong>{{ row.updatedAt || '暂无时间' }}</strong>
                      <div>
                        <el-button type="primary" link @click="selectedKnowledge = row">详细</el-button>
                        <el-button type="primary" link @click="openArticleEditor(row)">编辑</el-button>
                        <el-button type="danger" link @click="deleteArticle(row)">删除</el-button>
                      </div>
                    </div>
                  </div>
                  <el-empty v-if="filteredKnowledgeArticles.length === 0" description="暂无符合条件的知识文章" />
                </div>
              </el-tab-pane>
              <el-tab-pane label="常见问题" name="faqs">
                <div class="knowledge-card-list">
                  <div v-for="row in filteredFaqItems" :key="row.id" class="knowledge-item-card">
                    <div class="knowledge-item-main">
                      <div class="knowledge-item-title">
                        <strong>{{ row.question }}</strong>
                        <el-switch v-model="row.enabled" active-text="启用" inactive-text="停用" @change="toggleFaq(row)" />
                      </div>
                      <p>{{ row.answer }}</p>
                      <div class="knowledge-tags">
                        <el-tag effect="light">{{ row.categoryText }}</el-tag>
                        <el-tag type="warning" effect="plain">优先级 {{ row.priority }}</el-tag>
                      </div>
                    </div>
                    <div class="knowledge-item-side">
                      <span>更新时间</span>
                      <strong>{{ row.updatedAt || '暂无时间' }}</strong>
                      <div>
                        <el-button type="primary" link @click="selectedFaq = row">详细</el-button>
                        <el-button type="primary" link @click="openFaqEditor(row)">编辑</el-button>
                        <el-button type="danger" link @click="deleteFaq(row)">删除</el-button>
                      </div>
                    </div>
                  </div>
                  <el-empty v-if="filteredFaqItems.length === 0" description="暂无符合条件的常见问题" />
                </div>
              </el-tab-pane>
            </el-tabs>
          </div>
        </section>
        <section v-else-if="active === '规则配置'" class="rule-page">
          <div class="rule-stats">
            <div v-for="item in ruleMetrics" :key="item.label" class="card rule-stat">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="card rule-workbench">
            <div class="rule-head">
              <div>
                <h2>售后规则配置</h2>
                <p>配置售后申请、审核优先级、退款退货、价保、特殊商品等自动判断规则。</p>
              </div>
              <el-button type="primary" @click="openRuleEditor()">新增规则</el-button>
            </div>
            <div class="rule-filter-bar">
              <el-input v-model="ruleKeyword" clearable placeholder="搜索规则名称、规则说明、触发条件或执行动作" />
              <el-select v-model="ruleTypeFilter" placeholder="全部类型">
                <el-option label="全部类型" value="ALL" />
                <el-option v-for="item in ruleTypeOptions" :key="item.value" :label="item.label" :value="item.value" />
              </el-select>
              <el-select v-model="ruleEnabledFilter" placeholder="启用状态">
                <el-option label="全部状态" value="ALL" />
                <el-option label="已启用" value="ENABLED" />
                <el-option label="已停用" value="DISABLED" />
              </el-select>
            </div>
            <div class="rule-card-list">
              <div v-for="row in filteredAdminRules" :key="row.id" class="rule-item-card">
                <div class="rule-item-top">
                  <div>
                    <strong>{{ row.ruleName }}</strong>
                    <span>{{ row.content || '暂无规则说明' }}</span>
                  </div>
                  <div class="rule-item-status">
                    <el-tag effect="light">{{ row.ruleTypeText }}</el-tag>
                    <el-switch v-model="row.enabled" active-text="启用" inactive-text="停用" @change="toggleRule(row)" />
                  </div>
                </div>
                <div class="rule-flow">
                  <div>
                    <span>触发条件</span>
                    <p>{{ row.conditionsText || '无特殊触发条件' }}</p>
                  </div>
                  <div>
                    <span>执行动作</span>
                    <p>{{ row.actionText || '记录规则命中结果' }}</p>
                  </div>
                </div>
                <div class="rule-item-footer">
                  <span>更新时间：{{ row.updatedAt || '暂无时间' }}</span>
                  <div>
                    <el-button type="primary" link @click="openRuleEditor(row)">编辑</el-button>
                    <el-button type="danger" link @click="deleteRule(row)">删除</el-button>
                  </div>
                </div>
              </div>
              <el-empty v-if="filteredAdminRules.length === 0" description="暂无符合条件的售后规则" />
            </div>
          </div>
        </section>
        <section v-else-if="active === '评价分析'" class="review-page admin-review-page">
          <div class="card admin-review-hero">
            <div>
              <span class="section-eyebrow">评价风控中心</span>
              <h2>评价分析</h2>
              <p>按商家一级账号汇总其名下全部未删除评价，集中查看情感趋势、风险等级和异议状态。</p>
              <div class="admin-review-merchant-switch">
                <span>分析商家</span>
                <el-select v-model="selectedReviewMerchantKey" placeholder="选择商家一级账号" style="width: 260px">
                  <el-option
                    v-for="item in reviewMerchantOptions"
                    :key="item.value"
                    :label="item.label"
                    :value="item.value"
                  />
                </el-select>
              </div>
            </div>
            <div class="admin-review-hero-side">
              <strong>{{ reviewHeroRiskText }}</strong>
              <span>{{ selectedReviewMerchantLabel }}</span>
            </div>
          </div>
          <div class="review-stats admin-review-stats">
            <div v-for="item in reviewMetrics" :key="item.label" class="card review-stat admin-review-stat">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="admin-review-insights">
            <div class="card review-insight-card">
              <div class="panel-title">
                <div>
                  <h2>情感分布</h2>
                  <p>按照评价文本和星级结果进行归类。</p>
                </div>
              </div>
              <div class="review-chip-list">
                <div v-for="item in reviewSentimentSummary" :key="item.label" class="review-chip-row">
                  <span>{{ item.label }}</span>
                  <strong>{{ item.count }}</strong>
                  <em :style="{ width: item.percent + '%' }"></em>
                </div>
              </div>
            </div>
            <div class="card review-insight-card">
              <div class="panel-title">
                <div>
                  <h2>风险分布</h2>
                  <p>帮助管理员快速定位需要介入的评价。</p>
                </div>
              </div>
              <div class="review-chip-list">
                <div v-for="item in reviewRiskSummary" :key="item.label" class="review-chip-row">
                  <span>{{ item.label }}</span>
                  <strong>{{ item.count }}</strong>
                  <em :style="{ width: item.percent + '%' }"></em>
                </div>
              </div>
            </div>
          </div>
          <div class="card admin-review-list">
            <div class="panel-title admin-review-list-head">
              <div>
                <h2>评价异议处理</h2>
                <p>仅展示商家已提出异议的评价，审核与处置操作进入详情页完成。</p>
              </div>
              <el-button :loading="loadingAdminReviews" @click="refreshReviewData">刷新数据</el-button>
            </div>
            <div class="admin-review-cards">
              <div v-for="row in adminReviews" :key="row.id" class="admin-review-card">
                <div class="admin-review-main">
                  <div class="admin-review-title-line">
                    <strong>{{ row.productName }}</strong>
                    <div class="admin-review-tags">
                      <el-tag :type="sentimentTagType(row.sentiment)" effect="light">{{ row.sentiment }}</el-tag>
                      <el-tag :type="riskTagType(row.riskLevel)" effect="light">{{ row.riskLevel }}</el-tag>
                      <el-tag :type="disputeTagType(row.disputeStatus)" effect="plain">{{ row.disputeStatus }}</el-tag>
                    </div>
                  </div>
                  <p class="admin-review-content">{{ row.content }}</p>
                  <div class="admin-review-meta">
                    <span>{{ row.platform }}</span>
                    <span>{{ row.merchantName }}</span>
                    <span>{{ row.orderNo }}</span>
                    <span>{{ row.reviewedAt || '暂无评价时间' }}</span>
                  </div>
                </div>
                <div class="admin-review-action">
                  <el-rate :model-value="row.score" disabled size="small" />
                  <el-button type="primary" plain @click="selectedReview = row">查看详情</el-button>
                </div>
              </div>
              <el-empty v-if="adminReviews.length === 0" description="暂无评价异议" />
            </div>
          </div>
        </section>
        <section v-else-if="active === '争议订单处理'" class="dispute-page">
          <div class="dispute-stats">
            <div v-for="item in afterSaleDisputeMetrics" :key="item.label" class="card dispute-stat">
              <span>{{ item.label }}</span>
              <strong>{{ item.value }}</strong>
              <em>{{ item.description }}</em>
            </div>
          </div>
          <div class="card dispute-workbench">
            <div class="dispute-head">
              <div>
                <h2>平台介入售后争议</h2>
                <p>集中处理消费者二次申请、商家举证和平台裁定结果，确保争议售后闭环。</p>
              </div>
              <el-button type="primary" :loading="loadingAfterSaleDisputes" @click="loadAfterSaleDisputes">刷新</el-button>
            </div>
            <div class="dispute-filter-bar">
              <el-input v-model="afterSaleDisputeKeyword" clearable placeholder="搜索订单号、商家、商品或申请原因" />
              <el-select v-model="afterSaleDisputeStatusFilter" placeholder="处理状态">
                <el-option label="全部状态" value="ALL" />
                <el-option label="待审核" value="待审核" />
                <el-option label="已处理" value="已处理" />
              </el-select>
            </div>
            <div class="dispute-card-list">
              <div v-for="row in filteredAfterSaleDisputes" :key="row.id" class="dispute-item-card">
                <div class="dispute-item-top">
                  <div>
                    <strong>{{ row.orderNo }}</strong>
                    <span>{{ row.platformName }} / {{ row.shopName }}</span>
                  </div>
                  <el-tag :type="afterSaleDisputeTagType(row.status)">{{ row.status }}</el-tag>
                </div>
                <div class="dispute-product-line">
                  <div>
                    <span>商品</span>
                    <strong>{{ row.productName }}</strong>
                  </div>
                  <div>
                    <span>售后类型</span>
                    <strong>{{ row.afterSaleTypeText }}</strong>
                  </div>
                  <div>
                    <span>当前售后状态</span>
                    <strong>{{ row.afterSaleStatus }}</strong>
                  </div>
                  <div>
                    <span>申请时间</span>
                    <strong>{{ row.createdAt }}</strong>
                  </div>
                  <div>
                    <span>剩余处理时间</span>
                    <strong :class="{ 'danger-text': disputeRemainingTime(row).expired }">
                      {{ disputeRemainingTime(row).text }}
                    </strong>
                  </div>
                </div>
                <div class="dispute-reason-grid">
                  <div>
                    <span>消费者申请原因</span>
                    <p>{{ row.consumerReason || '暂无说明' }}</p>
                  </div>
                  <div>
                    <span>商家二次举证</span>
                    <p>{{ row.merchantEvidenceText || '商家暂未提交二次举证' }}</p>
                  </div>
                </div>
                <div class="dispute-item-footer">
                  <span>{{ row.merchantEvidenceImages.length || row.consumerEvidenceImages.length ? '已提交图片凭证' : '暂无图片凭证' }}</span>
                  <el-button type="primary" plain @click="selectedAfterSaleDispute = row">查看详细</el-button>
                </div>
              </div>
              <el-empty v-if="filteredAfterSaleDisputes.length === 0" description="暂无符合条件的争议订单" />
            </div>
          </div>
        </section>
        <section v-else-if="active === 'AI 配置'" class="ai-config-page">
          <div class="card ai-console-card">
            <div class="ai-console-head">
              <div class="ai-provider-card">
                <img class="deepseek-logo" :src="deepseekLogo" alt="DeepSeek" />
                <div>
                  <strong>{{ aiConfig.modelName || 'deepseek-chat' }}</strong>
                  <span>{{ aiConfig.baseUrl || '暂无模型接口地址' }}</span>
                </div>
              </div>
              <el-button type="primary" :loading="aiConfigLoading" @click="loadAiConfig">刷新配置</el-button>
            </div>
            <div class="ai-status-grid">
              <div class="ai-status-card">
                <span>服务状态</span>
                <strong :class="aiConfig.healthy ? 'status-ok' : 'status-danger'">{{ aiConfig.healthy ? '运行中' : '不可用' }}</strong>
                <em>{{ aiConfig.checkedAt || '尚未检测' }}</em>
              </div>
              <div class="ai-status-card">
                <span>API Key</span>
                <strong :class="aiConfig.apiKeyConfigured ? 'status-ok' : 'status-warning'">{{ aiConfig.apiKeyConfigured ? '已配置' : '未配置' }}</strong>
                <em>用于调用真实大模型服务</em>
                <el-button class="ai-key-edit-btn" size="small" type="primary" plain @click="openAiKeyDialog">编辑 API Key</el-button>
              </div>
              <div class="ai-status-card">
                <span>最大 Token</span>
                <strong>{{ aiConfig.maxTokens || 0 }}</strong>
                <em>单次回复长度上限</em>
              </div>
              <div class="ai-status-card">
                <span>超时时间</span>
                <strong>{{ aiConfig.timeoutSeconds || 0 }} 秒</strong>
                <em>接口调用等待时间</em>
              </div>
            </div>
            <div class="ai-config-grid">
              <div class="ai-info-panel">
                <h3>服务信息</h3>
                <div class="ai-info-row"><span>服务名称</span><strong>{{ aiConfig.serviceName || '暂无数据' }}</strong></div>
                <div class="ai-info-row"><span>服务地址</span><strong>{{ aiConfig.serviceUrl }}</strong></div>
                <div class="ai-info-row"><span>服务版本</span><strong>{{ aiConfig.serviceVersion || '暂无数据' }}</strong></div>
                <div class="ai-info-row"><span>模型提供商</span><strong>{{ providerText(aiConfig.provider) }}</strong></div>
              </div>
              <div class="ai-info-panel">
                <h3>回复策略</h3>
                <div class="ai-policy-box">
                  <span>回复模式</span>
                  <p>{{ aiConfig.replyMode || '暂无数据' }}</p>
                </div>
                <div class="ai-policy-box">
                  <span>兜底策略</span>
                  <p>{{ aiConfig.fallbackMode || '暂无数据' }}</p>
                </div>
                <div class="ai-policy-note">
                  当前 AI 服务用于消费者端客服自动回复；当服务不可用时，系统会提示转人工处理。
                </div>
              </div>
            </div>
          </div>
        </section>
        <section v-else-if="active === '操作日志'" class="operation-log-page">
          <div class="operation-log-toolbar card">
            <div>
              <h2>操作日志</h2>
              <p>记录管理员对账号、争议订单、评价异议、规则和知识库的关键操作。</p>
            </div>
            <div class="operation-log-actions">
              <el-select v-model="operationLogFilter" placeholder="操作类型" style="width: 180px">
                <el-option label="全部操作" value="ALL" />
                <el-option v-for="item in operationLogTypes" :key="item" :label="item" :value="item" />
              </el-select>
              <el-button plain type="danger" @click="clearOperationLogs">清空日志</el-button>
            </div>
          </div>
          <div class="card operation-log-card">
            <el-table :data="filteredOperationLogs" border>
              <el-table-column prop="time" label="操作时间" min-width="170" />
              <el-table-column label="管理员" width="160">
                <template #default="{ row }">
                  <div class="operation-admin-cell">
                    <img v-if="adminAvatarById(row.adminId)" :src="adminAvatarById(row.adminId)" alt="" />
                    <span>{{ row.adminName }}</span>
                  </div>
                </template>
              </el-table-column>
              <el-table-column prop="type" label="操作类型" width="150" />
              <el-table-column prop="target" label="操作对象" min-width="220" />
              <el-table-column prop="detail" label="操作内容" min-width="300" />
            </el-table>
            <el-empty v-if="filteredOperationLogs.length === 0" description="暂无操作日志" />
          </div>
        </section>
        <section v-else class="card">
          <h2>{{ active }}</h2>
          <p>该模块已预留管理入口，后续接入真实接口。</p>
        </section>
      </el-main>
    </el-container>
    <el-dialog v-model="banDialogVisible" class="ban-dialog" width="520px" :show-close="false" align-center>
      <div class="ban-dialog-head">
        <div>
          <span>ACCOUNT CONTROL</span>
          <h2>账号封禁处理</h2>
          <p>封禁后，该一级账号在消费者端或商家端登录时会被系统拦截。</p>
        </div>
        <button class="ban-dialog-close" @click="banDialogVisible = false">×</button>
      </div>
      <div v-if="banTarget" class="ban-account-card">
        <el-avatar :size="52" :src="banTarget.primaryAvatar">
          {{ avatarText(banTarget.primaryDisplayName, banTarget.primaryAccountNo) }}
        </el-avatar>
        <div>
          <strong>{{ banTarget.primaryDisplayName || '未设置名称' }}</strong>
          <span>{{ banTargetType === 'CONSUMER' ? '消费者一级账号' : '商家一级账号' }}：{{ banTarget.primaryAccountNo }}</span>
        </div>
        <el-tag :type="banTarget.primaryBanStatus === '已封禁' ? 'danger' : 'success'">
          {{ banTarget.primaryBanStatus || '正常' }}
        </el-tag>
      </div>
      <div v-if="banTarget?.primaryBanStatus === '已封禁'" class="ban-current-status">
        <strong>当前封禁</strong>
        <span>{{ banTarget.primaryBanDuration || '已封禁' }} · {{ banTarget.primaryBanUntil || '永久' }}</span>
      </div>
      <div class="ban-duration-panel">
        <div class="ban-section-title">
          <strong>选择封禁时长</strong>
          <span>到期后系统会自动恢复登录权限</span>
        </div>
        <div class="ban-duration-grid">
          <button
            v-for="item in banDurationOptions"
            :key="item.value"
            type="button"
            :class="{ active: banDuration === item.value }"
            @click="banDuration = item.value"
          >
            {{ item.label }}
          </button>
        </div>
      </div>
      <template #footer>
        <el-button v-if="banTarget?.primaryBanStatus === '已封禁'" type="success" plain :loading="banSubmitting" @click="unbanCurrentTarget">
          解除封禁
        </el-button>
        <el-button @click="banDialogVisible = false">取消</el-button>
        <el-button type="danger" :loading="banSubmitting" @click="submitPrimaryBan">确认封禁</el-button>
      </template>
    </el-dialog>
        <el-dialog v-model="reviewDetailVisible" title="评价异议详情" width="720px">
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
        <el-dialog v-model="aiKeyDialogVisible" title="编辑 API Key" width="620px" class="ai-key-dialog">
          <div class="ai-key-editor">
            <div class="ai-key-warning">
              API Key 会直接用于真实 AI 对话服务，保存后后续消费者端 AI 回复将使用新的密钥调用大模型。
            </div>
            <el-form label-position="top">
              <el-form-item label="当前 API Key">
                <el-input
                  :model-value="aiKeyInputValue"
                  type="text"
                  placeholder="暂无 API Key，请输入新的 API Key"
                  show-word-limit
                  @input="handleAiKeyInput"
                >
                  <template #append>
                    <el-button @click="aiKeyVisible = !aiKeyVisible">{{ aiKeyVisible ? '隐藏' : '查看' }}</el-button>
                  </template>
                </el-input>
              </el-form-item>
            </el-form>
            <div class="ai-key-meta">
              <span>当前状态</span>
              <strong :class="aiConfig.apiKeyConfigured ? 'status-ok' : 'status-warning'">
                {{ aiConfig.apiKeyConfigured ? '已配置' : '未配置' }}
              </strong>
            </div>
          </div>
          <template #footer>
            <el-button @click="aiKeyDialogVisible = false">取消</el-button>
            <el-button type="primary" :loading="aiKeySaving" @click="saveAiKey">保存并生效</el-button>
          </template>
        </el-dialog>
        <el-dialog v-model="afterSaleDisputeDetailVisible" title="争议订单详细" width="900px" class="dispute-dialog">
      <div v-if="selectedAfterSaleDispute" class="dispute-detail">
        <div class="dispute-detail-head">
          <div>
            <strong>{{ selectedAfterSaleDispute.orderNo }}</strong>
            <span>{{ selectedAfterSaleDispute.platformName }} / {{ selectedAfterSaleDispute.shopName }}</span>
          </div>
          <el-tag :type="afterSaleDisputeTagType(selectedAfterSaleDispute.status)">{{ selectedAfterSaleDispute.status }}</el-tag>
        </div>
        <div class="dispute-account-grid">
          <div class="dispute-account-card">
            <el-avatar v-if="selectedAfterSaleDispute.consumerPrimaryAvatar" :size="48" :src="selectedAfterSaleDispute.consumerPrimaryAvatar" />
            <el-avatar v-else :size="48">{{ avatarText(selectedAfterSaleDispute.consumerPrimaryDisplayName, selectedAfterSaleDispute.consumerPrimaryAccountNo) }}</el-avatar>
            <div>
              <span>消费者一级账号</span>
              <strong>{{ selectedAfterSaleDispute.consumerPrimaryDisplayName || '未绑定一级账号' }}</strong>
              <em>{{ selectedAfterSaleDispute.consumerPrimaryAccountNo || '暂无账号信息' }}</em>
            </div>
          </div>
          <div class="dispute-account-card">
            <el-avatar v-if="selectedAfterSaleDispute.merchantPrimaryAvatar" :size="48" :src="selectedAfterSaleDispute.merchantPrimaryAvatar" />
            <el-avatar v-else :size="48">{{ avatarText(selectedAfterSaleDispute.merchantPrimaryDisplayName, selectedAfterSaleDispute.merchantPrimaryAccountNo) }}</el-avatar>
            <div>
              <span>商家一级账号</span>
              <strong>{{ selectedAfterSaleDispute.merchantPrimaryDisplayName || '未绑定一级账号' }}</strong>
              <em>{{ selectedAfterSaleDispute.merchantPrimaryAccountNo || '暂无账号信息' }}</em>
            </div>
          </div>
        </div>
        <div class="dispute-detail-grid">
          <div><span>申请时间</span><strong>{{ selectedAfterSaleDispute.createdAt }}</strong></div>
          <div>
            <span>剩余处理时间</span>
            <strong :class="{ 'danger-text': disputeRemainingTime(selectedAfterSaleDispute).expired }">
              {{ disputeRemainingTime(selectedAfterSaleDispute).text }}
            </strong>
          </div>
          <div class="dispute-product-cell">
            <span>商品</span>
            <strong>{{ selectedAfterSaleDispute.productName }}</strong>
            <el-button link type="primary" @click="productDetailVisible = true">详细</el-button>
          </div>
          <div><span>售后类型</span><strong>{{ selectedAfterSaleDispute.afterSaleTypeText }}</strong></div>
          <div><span>当前售后状态</span><strong>{{ selectedAfterSaleDispute.afterSaleStatus }}</strong></div>
        </div>
        <div class="dispute-evidence-grid">
          <div class="dispute-evidence-card">
            <h3>消费者申请材料</h3>
            <p>{{ selectedAfterSaleDispute.consumerReason || '暂无申请原因' }}</p>
            <div v-if="selectedAfterSaleDispute.consumerEvidenceImages.length" class="evidence-list">
              <el-image
                v-for="image in selectedAfterSaleDispute.consumerEvidenceImages"
                :key="image"
                class="evidence-image"
                :src="image"
                :preview-src-list="selectedAfterSaleDispute.consumerEvidenceImages"
                fit="cover"
              />
            </div>
            <span v-else class="empty-evidence">暂无消费者凭证</span>
          </div>
          <div class="dispute-evidence-card">
            <h3>商家二次举证</h3>
            <p>{{ selectedAfterSaleDispute.merchantEvidenceText || '商家暂未提交二次举证' }}</p>
            <div v-if="selectedAfterSaleDispute.merchantEvidenceImages.length" class="evidence-list">
              <el-image
                v-for="image in selectedAfterSaleDispute.merchantEvidenceImages"
                :key="image"
                class="evidence-image"
                :src="image"
                :preview-src-list="selectedAfterSaleDispute.merchantEvidenceImages"
                fit="cover"
              />
            </div>
            <span v-else class="empty-evidence">暂无商家举证图片</span>
          </div>
        </div>
        <div class="platform-decision-card">
          <div>
            <span>平台处理结果</span>
            <strong>{{ adminDisputeResultText(selectedAfterSaleDispute.adminResult) }}</strong>
          </div>
          <div>
            <span>更新时间</span>
            <strong>{{ selectedAfterSaleDispute.updatedAt || '暂无时间' }}</strong>
          </div>
          <div v-if="disputeRefundAmountText(selectedAfterSaleDispute)">
            <span>裁决退款金额</span>
            <strong>{{ disputeRefundAmountText(selectedAfterSaleDispute) }}</strong>
          </div>
          <p>{{ selectedAfterSaleDispute.adminNote || '暂无平台处理说明' }}</p>
        </div>
      </div>
      <template #footer>
        <el-button @click="selectedAfterSaleDispute = null">关闭</el-button>
        <el-button
          v-if="selectedAfterSaleDispute?.status === '待审核'"
          type="primary"
          plain
          :loading="reviewingAfterSaleDispute"
          @click="partialRefundAfterSaleDispute"
        >
          部分退款
        </el-button>
        <el-button
          v-if="selectedAfterSaleDispute?.status === '待审核'"
          type="warning"
          :loading="reviewingAfterSaleDispute"
          @click="reviewAfterSaleDispute('SUPPORT_MERCHANT')"
        >
          支持商家
        </el-button>
        <el-button
          v-if="selectedAfterSaleDispute?.status === '待审核'"
          type="success"
          :loading="reviewingAfterSaleDispute"
          @click="reviewAfterSaleDispute('SUPPORT_CONSUMER')"
        >
          支持消费者
        </el-button>
      </template>
    </el-dialog>
    <el-dialog v-model="productDetailVisible" title="商品详细" width="760px" class="product-detail-dialog">
      <div v-if="selectedAfterSaleDispute" class="product-detail-panel">
        <div class="product-detail-main">
          <img :src="selectedDisputeProduct.image" :alt="selectedDisputeProduct.name" />
          <div>
            <span>{{ selectedAfterSaleDispute.platformName }} / {{ selectedAfterSaleDispute.shopName }}</span>
            <h3>{{ selectedDisputeProduct.name }}</h3>
            <strong>{{ selectedDisputeProduct.price }}</strong>
            <p>{{ selectedDisputeProduct.description }}</p>
          </div>
        </div>
        <div class="product-detail-grid">
          <div>
            <span>订单编号</span>
            <strong>{{ selectedAfterSaleDispute.orderNo }}</strong>
          </div>
          <div>
            <span>售后类型</span>
            <strong>{{ selectedAfterSaleDispute.afterSaleTypeText }}</strong>
          </div>
          <div>
            <span>售后政策</span>
            <strong>{{ selectedDisputeProduct.policy }}</strong>
          </div>
          <div>
            <span>商家</span>
            <strong>{{ selectedAfterSaleDispute.shopName }}</strong>
          </div>
        </div>
      </div>
      <template #footer>
        <el-button type="primary" @click="productDetailVisible = false">知道了</el-button>
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
    <el-dialog v-model="articleEditorVisible" :title="articleForm.id ? '编辑知识文章' : '新增知识文章'" width="760px">
      <el-form label-width="96px">
        <template v-if="!articleForm.id">
          <div class="ai-knowledge-source">
            <div class="ai-source-head">
              <div>
                <strong>AI 识别原始材料</strong>
                <span>粘贴平台政策、处理规范或选择文本、PDF、DOCX 文件，系统会自动识别标题、分类和知识内容。</span>
              </div>
              <label class="file-picker">
                选择文件
                <input
                  type="file"
                  accept=".txt,.md,.csv,.json,.log,.pdf,.docx,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                  @change="handleAdminKnowledgeFileChange"
                />
              </label>
            </div>
            <el-input
              v-model="adminKnowledgeSourceText"
              type="textarea"
              :rows="5"
              placeholder="例如：平台介入争议订单时，需要核对订单信息、聊天记录、售后凭证、商家审核意见和处理时间线。"
            />
            <div class="ai-source-actions">
              <span>{{ selectedAdminKnowledgeFileName || '未选择文件' }}</span>
              <el-button type="primary" :loading="extractingAdminKnowledge" @click="extractAdminKnowledge('article')">AI 识别并填充</el-button>
            </div>
          </div>
          <el-alert
            v-if="articleKnowledgeExtracted"
            type="success"
            show-icon
            :closable="false"
            title="AI 已完成识别，请确认下方标题、分类和内容是否准确，确认无误后点击保存。"
          />
        </template>
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
    <el-dialog v-model="faqEditorVisible" :title="faqForm.id ? '编辑常见问题' : '新增常见问题'" width="760px">
      <el-form label-width="96px">
        <template v-if="!faqForm.id">
          <div class="ai-knowledge-source">
            <div class="ai-source-head">
              <div>
                <strong>AI 识别原始材料</strong>
                <span>粘贴一段客服问答材料，或选择文本、PDF、DOCX 文件，系统会自动识别问题、分类和答案。</span>
              </div>
              <label class="file-picker">
                选择文件
                <input
                  type="file"
                  accept=".txt,.md,.csv,.json,.log,.pdf,.docx,application/pdf,application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                  @change="handleAdminKnowledgeFileChange"
                />
              </label>
            </div>
            <el-input
              v-model="adminKnowledgeSourceText"
              type="textarea"
              :rows="5"
              placeholder="例如：用户咨询商品发货后是否可以仅退款，需要说明未签收、物流异常、商家同意等场景下的处理方式。"
            />
            <div class="ai-source-actions">
              <span>{{ selectedAdminKnowledgeFileName || '未选择文件' }}</span>
              <el-button type="primary" :loading="extractingAdminKnowledge" @click="extractAdminKnowledge('faq')">AI 识别并填充</el-button>
            </div>
          </div>
          <el-alert
            v-if="faqKnowledgeExtracted"
            type="success"
            show-icon
            :closable="false"
            title="AI 已完成识别，请确认下方问题、分类和答案是否准确，确认无误后点击保存。"
          />
        </template>
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
import yuegouMarketIcon from './assets/platforms/yuegou-market-v2.svg'
import deepseekLogo from './assets/deepseek-logo.png'
import adminBrandIcon from './assets/brand/fusion-after-sale-icon.png'
import productBackpack from './assets/products/twenty-backpack-real.png'
import productCup from './assets/products/twenty-cup.png'
import productKeyboard from './assets/products/twenty-keyboard-real.png'
import productLamp from './assets/products/twenty-lamp.png'
import adminAvatarA from './assets/admins/admin-a.svg'
import adminAvatarB from './assets/admins/admin-b.svg'
import adminAvatarC from './assets/admins/admin-c.svg'
import adminAvatarD from './assets/admins/admin-d.svg'

const ADMIN_AUTH_STORAGE_KEY = 'admin-web-current-admin'
const ADMIN_OPERATION_LOG_STORAGE_KEY = 'admin-web-operation-logs'
const adminAccounts = [
  { id: 'admin-a', name: '管理员 A', key: 'A7mP4qR2', avatar: adminAvatarA },
  { id: 'admin-b', name: '管理员 B', key: 'z9KxT3vB', avatar: adminAvatarB },
  { id: 'admin-c', name: '管理员 C', key: 'Q6nL8sWa', avatar: adminAvatarC },
  { id: 'admin-d', name: '管理员 D', key: 'b2Hc7YdM', avatar: adminAvatarD }
]

const sections = [
  { label: '系统概览', icon: '总' },
  { label: '消费者管理', icon: '用' },
  { label: '商家管理', icon: '商' },
  { label: '外部平台', icon: '平' },
  { label: '同步监控', icon: '同' },
  { label: '知识库', icon: '知' },
  { label: '规则配置', icon: '规' },
  { label: '评价分析', icon: '评' },
  { label: '争议订单处理', icon: '争' },
  { label: 'AI 配置', icon: 'AI' },
  { label: '操作日志', icon: '志' }
]
const active = ref('系统概览')
const selectedAdminId = ref(adminAccounts[0].id)
const adminLoginKey = ref('')
const adminLoginLoading = ref(false)
const currentAdmin = ref<{ id: string; name: string } | null>(loadSavedAdmin())
const selectedAdmin = computed(() => adminAccounts.find((item) => item.id === selectedAdminId.value) || adminAccounts[0])
const currentAdminAvatar = computed(() => adminAccounts.find((item) => item.id === currentAdmin.value?.id)?.avatar || '')
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
  apiKey: '',
  apiKeyMasked: '',
  replyMode: '',
  fallbackMode: '',
  maxTokens: 0,
  timeoutSeconds: 0,
  checkedAt: ''
})
const aiKeyDialogVisible = ref(false)
const aiKeyVisible = ref(false)
const aiKeySaving = ref(false)
const aiKeyForm = ref({
  apiKey: ''
})
const aiKeyInputValue = computed(() => {
  if (aiKeyVisible.value) {
    return aiKeyForm.value.apiKey
  }
  return aiConfig.value.apiKeyMasked || maskApiKey(aiKeyForm.value.apiKey)
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
  aiCallCount: 0,
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
  platformCode?: string
  platformName: string
  secondaryAccountNo: string
  secondaryDisplayName: string
  bindStatus: string
  secondaryStatus: string
  boundAt: string
  primaryBanStatus?: string
  primaryBanDuration?: string
  primaryBanUntil?: string
}
type BindingGroup = {
  primaryAccountNo: string
  primaryDisplayName: string
  primaryAvatar?: string
  primaryBanStatus?: string
  primaryBanDuration?: string
  primaryBanUntil?: string
  bindings: BindingRow[]
}
type PlatformRow = {
  code: string
  name: string
  description: string
  status: string
  shops: number
  icon: string
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
  merchantAccountNo?: string
  merchantPrimaryAccountNo?: string
  merchantPrimaryDisplayName?: string
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
type AfterSaleDisputeRow = {
  id: number
  afterSaleId: number
  orderNo: string
  afterSaleType: string
  afterSaleTypeText: string
  afterSaleStatus: string
  productName: string
  platformName: string
  shopName: string
  consumerPrimaryAccountNo?: string
  consumerPrimaryDisplayName?: string
  consumerPrimaryAvatar?: string
  merchantPrimaryAccountNo?: string
  merchantPrimaryDisplayName?: string
  merchantPrimaryAvatar?: string
  consumerReason: string
  consumerEvidenceImages: string[]
  merchantEvidenceText: string
  merchantEvidenceImages: string[]
  adminResult: string
  adminNote: string
  status: string
  createdAt: string
  updatedAt: string
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
type AdminOperationLogRow = {
  id: string
  adminId: string
  adminName: string
  time: string
  type: string
  target: string
  detail: string
}
const consumerBindings = ref<BindingRow[]>([])
const merchantBindings = ref<BindingRow[]>([])
const consumerBindingKeyword = ref('')
const consumerBindingPlatformFilter = ref('ALL')
const selectedConsumerBindingGroup = ref<BindingGroup | null>(null)
const merchantBindingKeyword = ref('')
const merchantBindingPlatformFilter = ref('ALL')
const selectedMerchantBindingGroup = ref<BindingGroup | null>(null)
const banDialogVisible = ref(false)
const banSubmitting = ref(false)
const banTarget = ref<BindingGroup | null>(null)
const banTargetType = ref<'CONSUMER' | 'MERCHANT'>('CONSUMER')
const banDuration = ref('7D')
const banDurationOptions = [
  { label: '1天', value: '1D' },
  { label: '3天', value: '3D' },
  { label: '7天', value: '7D' },
  { label: '一个月', value: '1M' },
  { label: '半年', value: '6M' },
  { label: '一年', value: '1Y' },
  { label: '十年', value: '10Y' },
  { label: '永久', value: 'PERMANENT' }
]
const selectedPlatform = ref<PlatformRow | null>(null)
const syncLogs = ref<SyncLogRow[]>([])
const selectedSyncLog = ref<SyncLogRow | null>(null)
const adminReviews = ref<ReviewRow[]>([])
const adminReviewAnalysisRows = ref<ReviewRow[]>([])
const selectedReviewMerchantKey = ref('')
const afterSaleDisputes = ref<AfterSaleDisputeRow[]>([])
const afterSaleDisputeKeyword = ref('')
const afterSaleDisputeStatusFilter = ref('ALL')
const adminRules = ref<RuleRow[]>([])
const ruleKeyword = ref('')
const ruleTypeFilter = ref('ALL')
const ruleEnabledFilter = ref('ALL')
const knowledgeArticles = ref<KnowledgeArticleRow[]>([])
const faqItems = ref<FaqRow[]>([])
const knowledgeKeyword = ref('')
const knowledgeCategoryFilter = ref('ALL')
const selectedReview = ref<ReviewRow | null>(null)
const selectedAfterSaleDispute = ref<AfterSaleDisputeRow | null>(null)
const productDetailVisible = ref(false)
const afterSaleDisputeRefundAmounts = ref<Record<number, string>>({})
const selectedKnowledge = ref<KnowledgeArticleRow | null>(null)
const selectedFaq = ref<FaqRow | null>(null)
const deletingReview = ref(false)
const reviewingDispute = ref(false)
const loadingAdminReviews = ref(false)
const loadingAfterSaleDisputes = ref(false)
const reviewingAfterSaleDispute = ref(false)
const ruleEditorVisible = ref(false)
const savingRule = ref(false)
const knowledgeTab = ref('articles')
const articleEditorVisible = ref(false)
const faqEditorVisible = ref(false)
const savingKnowledge = ref(false)
const operationLogs = ref<AdminOperationLogRow[]>(loadSavedOperationLogs())
const operationLogFilter = ref('ALL')
const operationLogTypes = ['封禁账号', '解封账号', '争议订单处理', '评价异议处理', '规则配置', '知识库新增']
const adminKnowledgeSourceText = ref('')
const selectedAdminKnowledgeFileName = ref('')
const extractingAdminKnowledge = ref(false)
const articleKnowledgeExtracted = ref(false)
const faqKnowledgeExtracted = ref(false)
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
const afterSaleDisputeDetailVisible = computed({
  get: () => selectedAfterSaleDispute.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedAfterSaleDispute.value = null
      productDetailVisible.value = false
    }
  }
})
const selectedDisputeProduct = computed(() => buildDisputeProductDetail(selectedAfterSaleDispute.value))
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
const consumerBindingDetailVisible = computed({
  get: () => selectedConsumerBindingGroup.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedConsumerBindingGroup.value = null
    }
  }
})
const merchantBindingDetailVisible = computed({
  get: () => selectedMerchantBindingGroup.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedMerchantBindingGroup.value = null
    }
  }
})
const platformDetailVisible = computed({
  get: () => selectedPlatform.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedPlatform.value = null
    }
  }
})
const syncDetailVisible = computed({
  get: () => selectedSyncLog.value !== null,
  set: (visible: boolean) => {
    if (!visible) {
      selectedSyncLog.value = null
    }
  }
})
const metrics = computed(() => [
  { label: '商家数', value: formatNumber(overview.value.merchantCount), description: '电商平台中已启用的商家账号' },
  { label: '绑定店铺', value: formatNumber(overview.value.boundShopCount), description: '商家一级账号已绑定的店铺数量' },
  { label: '今日同步', value: formatNumber(overview.value.todaySyncCount), description: '今日更新的订单、售后和评价数据' },
  { label: 'AI 调用', value: formatNumber(overview.value.aiCallCount), description: '来自数据库 AI 调用日志的真实统计' }
])
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
  { task: '电商平台订单数据同步', status: '暂无数据', count: 0, time: '' },
  { task: '电商平台售后数据同步', status: '暂无数据', count: 0, time: '' },
  { task: '电商平台评价数据同步', status: '暂无数据', count: 0, time: '' }
])
const syncMetrics = computed(() => {
  const list = syncOverview.value
  const totalCount = list.reduce((sum, item) => sum + item.count, 0)
  const normalCount = list.filter((item) => item.status === '正常').length
  const timeRows = list.map((item) => item.time).filter(Boolean).sort()
  const latestTime = timeRows.length > 0 ? timeRows[timeRows.length - 1] : '暂无时间'
  return [
    { label: '同步任务数', value: formatNumber(list.length), description: '当前纳入监控的数据同步任务' },
    { label: '正常任务', value: formatNumber(normalCount), description: '最近一次同步结果正常的任务' },
    { label: '累计同步量', value: formatNumber(totalCount), description: '订单、售后、评价累计同步数量' },
    { label: '最近同步', value: latestTime, description: '最近一次数据更新时间' }
  ]
})
const bindingSummary = computed(() => [
  { label: '消费者一级账号', value: formatNumber(countUniquePrimary(consumerBindings.value)) },
  { label: '商家一级账号', value: formatNumber(countUniquePrimary(merchantBindings.value)) },
  { label: '绑定消费者账号', value: formatNumber(countBoundSecondary(consumerBindings.value)) },
  { label: '绑定商家店铺', value: formatNumber(countBoundSecondary(merchantBindings.value)) }
])
const consumerBindingGroups = computed(() => groupBindingsByPrimary(consumerBindings.value))
const filteredConsumerBindingGroups = computed(() => {
  const keyword = consumerBindingKeyword.value.trim().toLowerCase()
  const platform = consumerBindingPlatformFilter.value
  return consumerBindingGroups.value
    .map((group) => {
      const groupText = [group.primaryAccountNo, group.primaryDisplayName].join(' ').toLowerCase()
      const matchedByPrimary = Boolean(keyword && groupText.includes(keyword))
      return {
        ...group,
        bindings: group.bindings.filter((item) => {
        const matchesPlatform = platform === 'ALL' || item.platformName === platform
        const haystack = [
          item.primaryAccountNo,
          item.primaryDisplayName,
          item.platformName,
          item.secondaryAccountNo,
          item.secondaryDisplayName
        ].join(' ').toLowerCase()
        return matchesPlatform && (!keyword || haystack.includes(keyword))
        }),
        matchedByPrimary
      }
    })
    .filter((group) => group.bindings.length > 0 || (platform === 'ALL' && (group.matchedByPrimary || !keyword)))
})
const consumerBindingPlatformOptions = computed(() => Array.from(new Set(consumerBindings.value.map((item) => item.platformName).filter(Boolean))))
const consumerBindingMetrics = computed(() => {
  const primaryTotal = consumerBindingGroups.value.length
  const secondaryTotal = countBoundSecondary(consumerBindings.value)
  const platformTotal = consumerBindingPlatformOptions.value.length
  const multiBindTotal = consumerBindingGroups.value.filter((item) => item.bindings.length > 1).length
  return [
    { label: '一级用户数', value: formatNumber(primaryTotal), description: '已进入平台账号体系的消费者' },
    { label: '绑定账号数', value: formatNumber(secondaryTotal), description: '消费者绑定的二级平台账号' },
    { label: '接入平台数', value: formatNumber(platformTotal), description: '当前存在绑定关系的平台' },
    { label: '多账号用户', value: formatNumber(multiBindTotal), description: '绑定多个二级账号的一级用户' }
  ]
})
const merchantBindingGroups = computed(() => groupBindingsByPrimary(merchantBindings.value))
const filteredMerchantBindingGroups = computed(() => {
  const keyword = merchantBindingKeyword.value.trim().toLowerCase()
  const platform = merchantBindingPlatformFilter.value
  return merchantBindingGroups.value
    .map((group) => {
      const groupText = [group.primaryAccountNo, group.primaryDisplayName].join(' ').toLowerCase()
      const matchedByPrimary = Boolean(keyword && groupText.includes(keyword))
      return {
        ...group,
        bindings: group.bindings.filter((item) => {
        const matchesPlatform = platform === 'ALL' || item.platformName === platform
        const haystack = [
          item.primaryAccountNo,
          item.primaryDisplayName,
          item.platformName,
          item.secondaryAccountNo,
          item.secondaryDisplayName
        ].join(' ').toLowerCase()
        return matchesPlatform && (!keyword || haystack.includes(keyword))
        }),
        matchedByPrimary
      }
    })
    .filter((group) => group.bindings.length > 0 || (platform === 'ALL' && (group.matchedByPrimary || !keyword)))
})
const merchantBindingPlatformOptions = computed(() => Array.from(new Set(merchantBindings.value.map((item) => item.platformName).filter(Boolean))))
const merchantBindingMetrics = computed(() => {
  const primaryTotal = merchantBindingGroups.value.length
  const shopTotal = countBoundSecondary(merchantBindings.value)
  const platformTotal = merchantBindingPlatformOptions.value.length
  const multiShopTotal = merchantBindingGroups.value.filter((item) => item.bindings.length > 1).length
  return [
    { label: '一级商家数', value: formatNumber(primaryTotal), description: '已进入平台账号体系的商家' },
    { label: '绑定店铺数', value: formatNumber(shopTotal), description: '商家绑定的二级平台店铺' },
    { label: '接入平台数', value: formatNumber(platformTotal), description: '当前存在商家绑定的平台' },
    { label: '多店铺商家', value: formatNumber(multiShopTotal), description: '绑定多个店铺的一级商家' }
  ]
})
const filteredOperationLogs = computed(() => {
  if (operationLogFilter.value === 'ALL') {
    return operationLogs.value
  }
  return operationLogs.value.filter((item) => item.type === operationLogFilter.value)
})
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
const reviewMerchantOptions = computed(() => {
  const map = new Map<string, { value: string; label: string; count: number }>()
  adminReviewAnalysisRows.value.forEach((item) => {
    const value = item.merchantPrimaryAccountNo || ''
    if (!value || value === item.merchantAccountNo) {
      return
    }
    const label = `${item.merchantPrimaryDisplayName || '未命名商家'}（${value}）`
    const current = map.get(value) || { value, label, count: 0 }
    current.count += 1
    map.set(value, current)
  })
  return Array.from(map.values()).map((item) => ({
    ...item,
    label: `${item.label} · ${item.count} 条评价`
  }))
})
const selectedReviewAnalysisRows = computed(() => {
  if (!selectedReviewMerchantKey.value) {
    return []
  }
  return adminReviewAnalysisRows.value.filter((item) => item.merchantPrimaryAccountNo === selectedReviewMerchantKey.value)
})
const selectedReviewMerchantLabel = computed(() => {
  return reviewMerchantOptions.value.find((item) => item.value === selectedReviewMerchantKey.value)?.label || '暂无可分析商家'
})
const reviewMetrics = computed(() => {
  const rows = selectedReviewAnalysisRows.value
  const total = rows.length
  const highRisk = rows.filter((item) => item.riskLevel === '高风险').length
  const negative = rows.filter((item) => item.sentiment === '负向').length
  const averageScore = total === 0
    ? '0.0'
    : (rows.reduce((sum, item) => sum + item.score, 0) / total).toFixed(1)
  return [
    { label: '评价总数', value: formatNumber(total), description: '该一级商家全部未删除评价' },
    { label: '平均星级', value: averageScore, description: '该商家的商品与服务综合评分' },
    { label: '负向评价', value: formatNumber(negative), description: '需要重点跟进的反馈' },
    { label: '高风险评价', value: formatNumber(highRisk), description: '可能影响商家信誉' }
  ]
})
const reviewHeroRiskText = computed(() => {
  const rows = selectedReviewAnalysisRows.value
  const pendingDisputes = rows.filter((item) => item.disputeStatus === '待审核').length
  const highRisk = rows.filter((item) => item.riskLevel === '高风险').length
  if (pendingDisputes > 0) {
    return `${pendingDisputes} 条异议待审`
  }
  if (highRisk > 0) {
    return `${highRisk} 条高风险`
  }
  return '暂无紧急风险'
})
const reviewSentimentSummary = computed(() => {
  const labels = ['正向', '中性', '负向']
  const rows = selectedReviewAnalysisRows.value
  const total = Math.max(1, rows.length)
  return labels.map((label) => {
    const count = rows.filter((item) => item.sentiment === label).length
    return {
      label,
      count: formatNumber(count),
      percent: Math.max(count === 0 ? 4 : 10, Math.round((count / total) * 100))
    }
  })
})
const reviewRiskSummary = computed(() => {
  const labels = ['低风险', '中风险', '高风险', '已删除']
  const rows = selectedReviewAnalysisRows.value
  const total = Math.max(1, rows.length)
  return labels.map((label) => {
    const count = rows.filter((item) => item.riskLevel === label).length
    return {
      label,
      count: formatNumber(count),
      percent: Math.max(count === 0 ? 4 : 10, Math.round((count / total) * 100))
    }
  })
})
const afterSaleDisputeMetrics = computed(() => {
  const total = afterSaleDisputes.value.length
  const pending = afterSaleDisputes.value.filter((item) => item.status === '待审核').length
  const resolved = afterSaleDisputes.value.filter((item) => item.status === '已处理').length
  const hasMerchantEvidence = afterSaleDisputes.value.filter((item) => Boolean(item.merchantEvidenceText || item.merchantEvidenceImages.length)).length
  return [
    { label: '争议订单总数', value: formatNumber(total), description: '消费者申请平台介入的售后单' },
    { label: '待平台审核', value: formatNumber(pending), description: '需要管理员裁定的争议' },
    { label: '已处理', value: formatNumber(resolved), description: '已给出平台处理结果' },
    { label: '商家已举证', value: formatNumber(hasMerchantEvidence), description: '商家提交了二次说明或图片' }
  ]
})
const filteredAfterSaleDisputes = computed(() => {
  const keyword = afterSaleDisputeKeyword.value.trim().toLowerCase()
  return afterSaleDisputes.value.filter((item) => {
    const statusMatched = afterSaleDisputeStatusFilter.value === 'ALL' || item.status === afterSaleDisputeStatusFilter.value
    const text = [
      item.orderNo,
      item.platformName,
      item.shopName,
      item.productName,
      item.afterSaleTypeText,
      item.consumerReason,
      item.merchantEvidenceText
    ].join(' ').toLowerCase()
    return statusMatched && (!keyword || text.includes(keyword))
  })
})
const ruleMetrics = computed(() => {
  const total = adminRules.value.length
  const enabled = adminRules.value.filter((item) => item.enabled).length
  const disabled = total - enabled
  const types = new Set(adminRules.value.map((item) => item.ruleType)).size
  return [
    { label: '规则总数', value: formatNumber(total), description: '当前售后规则配置数量' },
    { label: '已启用', value: formatNumber(enabled), description: '正在参与业务判断的规则' },
    { label: '已停用', value: formatNumber(disabled), description: '暂不参与售后处理判断' },
    { label: '规则类型', value: formatNumber(types), description: '覆盖的售后处理场景' }
  ]
})
const ruleTypeOptions = computed(() => {
  const map = new Map<string, string>()
  adminRules.value.forEach((item) => {
    map.set(item.ruleType, item.ruleTypeText || item.ruleType)
  })
  return Array.from(map.entries()).map(([value, label]) => ({ value, label }))
})
const filteredAdminRules = computed(() => {
  const keyword = ruleKeyword.value.trim().toLowerCase()
  return adminRules.value.filter((item) => {
    const matchType = ruleTypeFilter.value === 'ALL' || item.ruleType === ruleTypeFilter.value
    const matchEnabled = ruleEnabledFilter.value === 'ALL'
      || (ruleEnabledFilter.value === 'ENABLED' && item.enabled)
      || (ruleEnabledFilter.value === 'DISABLED' && !item.enabled)
    const text = [
      item.ruleName,
      item.ruleTypeText,
      item.content,
      item.conditionsText,
      item.actionText
    ].join(' ').toLowerCase()
    return matchType && matchEnabled && (!keyword || text.includes(keyword))
  })
})
const knowledgeMetrics = computed(() => {
  const articleTotal = knowledgeArticles.value.length
  const published = knowledgeArticles.value.filter((item) => item.status === 'PUBLISHED').length
  const faqTotal = faqItems.value.length
  const enabledFaq = faqItems.value.filter((item) => item.enabled).length
  return [
    { label: '知识文章', value: formatNumber(articleTotal), description: '平台政策与处理规范' },
    { label: '已发布文章', value: formatNumber(published), description: '当前可被业务引用' },
    { label: '常见问题', value: formatNumber(faqTotal), description: '客服高频问答内容' },
    { label: '启用 FAQ', value: formatNumber(enabledFaq), description: '可用于客服回复' }
  ]
})
const knowledgeCategoryOptions = computed(() => {
  const articleCategories = knowledgeArticles.value.map((item) => item.categoryText)
  const faqCategories = faqItems.value.map((item) => item.categoryText)
  return Array.from(new Set([...articleCategories, ...faqCategories].filter(Boolean)))
})
const filteredKnowledgeArticles = computed(() => knowledgeArticles.value.filter((item) => {
  const keyword = knowledgeKeyword.value.trim().toLowerCase()
  const categoryMatched = knowledgeCategoryFilter.value === 'ALL' || item.categoryText === knowledgeCategoryFilter.value
  const text = [item.title, item.content, item.categoryText, item.tagsJson, item.statusText].join(' ').toLowerCase()
  return categoryMatched && (!keyword || text.includes(keyword))
}))
const filteredFaqItems = computed(() => faqItems.value.filter((item) => {
  const keyword = knowledgeKeyword.value.trim().toLowerCase()
  const categoryMatched = knowledgeCategoryFilter.value === 'ALL' || item.categoryText === knowledgeCategoryFilter.value
  const text = [item.question, item.answer, item.categoryText, item.enabled ? '启用' : '停用'].join(' ').toLowerCase()
  return categoryMatched && (!keyword || text.includes(keyword))
}))
const platforms = computed(() => {
  const twentyMallShopCount = countUniqueBoundShops('万象商城')
  const yuegouShopCount = countUniqueBoundShops('悦购集市')
  return [
    { code: 'DOUYIN', name: '抖音电商', description: '真实抖店开放平台待接入', status: '未接入', shops: 0, icon: douyinIcon },
    { code: 'TAOBAO', name: '淘宝', description: '预留淘宝开放平台接入', status: '规划中', shops: 0, icon: taobaoIcon },
    { code: 'PDD', name: '拼多多', description: '预留拼多多开放平台接入', status: '规划中', shops: 0, icon: pddIcon },
    { code: 'JD', name: '京东', description: '预留京东开放平台接入', status: '规划中', shops: 0, icon: jdIcon },
    {
      code: 'TWENTY_MALL',
      name: '万象商城',
      description: '自建数据库模拟真实电商平台，提供订单、售后、评价等演示数据',
      status: twentyMallShopCount > 0 ? '启用' : '未绑定',
      shops: twentyMallShopCount,
      icon: twentyMallIcon
    },
    {
      code: 'YUEGOU_MARKET',
      name: '悦购集市',
      description: '第二个自建数据库模拟电商平台，可独立绑定账号并同步业务关系',
      status: yuegouShopCount > 0 ? '启用' : '未绑定',
      shops: yuegouShopCount,
      icon: yuegouMarketIcon
    }
  ]
})
const platformMetrics = computed(() => {
  const list = platforms.value
  const enabledCount = list.filter((item) => item.status === '启用').length
  const plannedCount = list.filter((item) => item.status === '规划中').length
  const shopTotal = list.reduce((sum, item) => sum + item.shops, 0)
  return [
    { label: '平台总数', value: formatNumber(list.length), description: '系统预留和已接入平台' },
    { label: '已启用平台', value: formatNumber(enabledCount), description: '当前可进行业务同步的平台' },
    { label: '规划中平台', value: formatNumber(plannedCount), description: '后续可接入的开放平台' },
    { label: '绑定店铺数', value: formatNumber(shopTotal), description: '全部平台累计绑定店铺' }
  ]
})

function loadSavedAdmin() {
  try {
    const saved = localStorage.getItem(ADMIN_AUTH_STORAGE_KEY)
    if (!saved) return null
    const parsed = JSON.parse(saved) as { id?: string; name?: string }
    const matched = adminAccounts.find((item) => item.id === parsed.id)
    return matched ? { id: matched.id, name: matched.name } : null
  } catch {
    return null
  }
}

function loadSavedOperationLogs(): AdminOperationLogRow[] {
  try {
    const saved = localStorage.getItem(ADMIN_OPERATION_LOG_STORAGE_KEY)
    if (!saved) return []
    const rows = JSON.parse(saved)
    return Array.isArray(rows) ? rows : []
  } catch {
    return []
  }
}

function saveOperationLogs() {
  localStorage.setItem(ADMIN_OPERATION_LOG_STORAGE_KEY, JSON.stringify(operationLogs.value.slice(0, 300)))
}

function adminAvatarById(adminId: string) {
  return adminAccounts.find((item) => item.id === adminId)?.avatar || ''
}

function recordAdminOperation(type: string, target: string, detail: string) {
  const admin = currentAdmin.value || selectedAdmin.value
  operationLogs.value = [
    {
      id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
      adminId: admin.id,
      adminName: admin.name,
      time: formatLocalDateTime(new Date()),
      type,
      target,
      detail
    },
    ...operationLogs.value
  ].slice(0, 300)
  saveOperationLogs()
}

async function clearOperationLogs() {
  try {
    await ElMessageBox.confirm('确认清空管理员操作日志吗？此操作只会清空当前浏览器保存的日志。', '清空操作日志', {
      confirmButtonText: '确认清空',
      cancelButtonText: '取消',
      type: 'warning'
    })
  } catch {
    return
  }
  operationLogs.value = []
  saveOperationLogs()
  ElMessage.success('操作日志已清空')
}

function loadAdminData() {
  loadOverview()
  loadAccountBindings()
  loadSyncLogs()
  loadAdminReviewAnalysis()
  loadAdminReviews()
  loadAfterSaleDisputes()
  loadAdminRules()
  loadKnowledge()
  loadAiConfig()
}

function selectLoginAdmin(adminId: string) {
  selectedAdminId.value = adminId
  adminLoginKey.value = ''
}

function loginAdmin() {
  adminLoginLoading.value = true
  try {
    const key = adminLoginKey.value.trim()
    const matched = selectedAdmin.value
    if (!matched || matched.key !== key) {
      ElMessage({ type: 'error', message: `${matched?.name || '管理员'}秘钥错误，请重新输入` })
      return
    }
    currentAdmin.value = { id: matched.id, name: matched.name }
    localStorage.setItem(ADMIN_AUTH_STORAGE_KEY, JSON.stringify(currentAdmin.value))
    adminLoginKey.value = ''
    ElMessage({ type: 'success', message: `${matched.name} 登录成功` })
    loadAdminData()
  } finally {
    adminLoginLoading.value = false
  }
}

function logoutAdmin() {
  currentAdmin.value = null
  localStorage.removeItem(ADMIN_AUTH_STORAGE_KEY)
  adminLoginKey.value = ''
  active.value = '系统概览'
}

onMounted(() => {
  if (currentAdmin.value) {
    loadAdminData()
  }
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
      apiKey: payload.apiKey || '',
      apiKeyMasked: payload.apiKeyMasked || '',
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

function openAiKeyDialog() {
  aiKeyForm.value.apiKey = aiConfig.value.apiKey || ''
  aiKeyVisible.value = false
  aiKeyDialogVisible.value = true
}

function maskApiKey(value: string) {
  const normalized = value.trim()
  if (!normalized) {
    return ''
  }
  if (normalized.length <= 8) {
    return '*'.repeat(normalized.length)
  }
  const prefix = normalized.startsWith('sk-') ? normalized.slice(0, 5) : normalized.slice(0, 4)
  const suffix = normalized.slice(-4)
  return `${prefix}${'*'.repeat(Math.max(normalized.length - prefix.length - suffix.length, 4))}${suffix}`
}

function handleAiKeyInput(value: string | number) {
  const nextValue = String(value)
  if (!aiKeyVisible.value) {
    aiKeyVisible.value = true
    const maskedValue = aiConfig.value.apiKeyMasked || maskApiKey(aiKeyForm.value.apiKey)
    aiKeyForm.value.apiKey = nextValue === maskedValue ? aiKeyForm.value.apiKey : nextValue.replace(maskedValue, '')
    return
  }
  aiKeyForm.value.apiKey = nextValue
}

async function saveAiKey() {
  aiKeySaving.value = true
  try {
    const response = await fetch('http://localhost:9000/api/ai/config', {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        api_key: aiKeyForm.value.apiKey.trim()
      })
    })
    if (!response.ok) {
      throw new Error('保存 API Key 失败')
    }
    const result = await response.json()
    const payload = result.data || result
    aiConfig.value = {
      ...aiConfig.value,
      healthy: true,
      serviceName: payload.serviceName || aiConfig.value.serviceName,
      serviceVersion: payload.serviceVersion || aiConfig.value.serviceVersion,
      serviceUrl: payload.serviceUrl || aiConfig.value.serviceUrl,
      provider: payload.provider || aiConfig.value.provider,
      modelName: payload.modelName || aiConfig.value.modelName,
      baseUrl: payload.baseUrl || aiConfig.value.baseUrl,
      apiKeyConfigured: Boolean(payload.apiKeyConfigured),
      apiKey: payload.apiKey || '',
      apiKeyMasked: payload.apiKeyMasked || '',
      replyMode: payload.replyMode || aiConfig.value.replyMode,
      fallbackMode: payload.fallbackMode || aiConfig.value.fallbackMode,
      maxTokens: Number(payload.maxTokens || aiConfig.value.maxTokens || 0),
      timeoutSeconds: Number(payload.timeoutSeconds || aiConfig.value.timeoutSeconds || 0),
      checkedAt: formatLocalDateTime(new Date())
    }
    aiKeyDialogVisible.value = false
    aiKeyVisible.value = false
    ElMessage.success('API Key 已保存，真实 AI 对话服务已使用新配置')
  } catch {
    ElMessage.error('保存 API Key 失败，请确认 AI 服务已启动')
  } finally {
    aiKeySaving.value = false
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
        aiCallCount: Number(payload.data.aiCallCount || 0),
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
      aiCallCount: 0,
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
      return
    }
    ElMessage.error(payload.message || '账号绑定数据读取失败')
  } catch {
    consumerBindings.value = []
    merchantBindings.value = []
    ElMessage.error('账号绑定数据读取失败，请确认后端服务已启动')
  }
}

function openBanDialog(group: BindingGroup, accountType: 'CONSUMER' | 'MERCHANT') {
  banTarget.value = group
  banTargetType.value = accountType
  banDuration.value = '7D'
  banDialogVisible.value = true
}

async function submitPrimaryBan() {
  if (!banTarget.value) return
  banSubmitting.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/primary-accounts/ban', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accountNo: banTarget.value.primaryAccountNo,
        accountType: banTargetType.value,
        duration: banDuration.value
      })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '封禁失败')
    }
    recordAdminOperation(
      '封禁账号',
      `${banTargetType.value === 'CONSUMER' ? '消费者' : '商家'}：${banTarget.value.primaryAccountNo}`,
      `封禁账号“${banTarget.value.primaryDisplayName || banTarget.value.primaryAccountNo}”，封禁时长：${banDurationOptions.find((item) => item.value === banDuration.value)?.label || banDuration.value}`
    )
    ElMessage.success('账号已封禁，登录时将提示该账号已被封禁')
    banDialogVisible.value = false
    banTarget.value = null
    await loadAccountBindings()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '封禁失败')
  } finally {
    banSubmitting.value = false
  }
}

async function unbanPrimaryAccount(group: BindingGroup, accountType: 'CONSUMER' | 'MERCHANT') {
  try {
    await ElMessageBox.confirm(`确认解除 ${group.primaryDisplayName || group.primaryAccountNo} 的封禁吗？`, '解除封禁', {
      confirmButtonText: '确认解除',
      cancelButtonText: '取消',
      type: 'warning'
    })
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/primary-accounts/unban', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accountNo: group.primaryAccountNo,
        accountType
      })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '解除封禁失败')
    }
    recordAdminOperation(
      '解封账号',
      `${accountType === 'CONSUMER' ? '消费者' : '商家'}：${group.primaryAccountNo}`,
      `解除账号“${group.primaryDisplayName || group.primaryAccountNo}”的封禁`
    )
    ElMessage.success('账号已解除封禁')
    await loadAccountBindings()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error(error instanceof Error ? error.message : '解除封禁失败')
    }
  }
}

async function unbanCurrentTarget() {
  if (!banTarget.value) return
  banSubmitting.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/primary-accounts/unban', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        accountNo: banTarget.value.primaryAccountNo,
        accountType: banTargetType.value
      })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '解除封禁失败')
    }
    recordAdminOperation(
      '解封账号',
      `${banTargetType.value === 'CONSUMER' ? '消费者' : '商家'}：${banTarget.value.primaryAccountNo}`,
      `解除账号“${banTarget.value.primaryDisplayName || banTarget.value.primaryAccountNo}”的封禁`
    )
    ElMessage.success('账号已解除封禁')
    banDialogVisible.value = false
    banTarget.value = null
    await loadAccountBindings()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '解除封禁失败')
  } finally {
    banSubmitting.value = false
  }
}

async function loadSyncLogs() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/sync-monitor')
    const payload = await response.json()
    if (payload.code === '200' && Array.isArray(payload.data)) {
      syncLogs.value = payload.data.map((item: SyncLogRow) => ({
        task: normalizeSyncTaskName(item.task),
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
  loadingAdminReviews.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/reviews')
    const payload = await response.json()
    if (payload.code === '200' && Array.isArray(payload.data)) {
      adminReviews.value = payload.data.map(mapReviewRow)
      return
    }
  } catch {
    // 页面保持空状态，避免展示不真实的模拟数据。
  } finally {
    loadingAdminReviews.value = false
  }
  adminReviews.value = []
}

async function loadAdminReviewAnalysis() {
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/reviews/analysis')
    const payload = await response.json()
    if (payload.code === '200' && Array.isArray(payload.data)) {
      adminReviewAnalysisRows.value = payload.data.map(mapReviewRow)
      ensureSelectedReviewMerchant()
      return
    }
  } catch {
    // 页面保持空状态，避免展示不真实的模拟数据。
  }
  adminReviewAnalysisRows.value = []
  selectedReviewMerchantKey.value = ''
}

async function refreshReviewData() {
  loadingAdminReviews.value = true
  try {
    await Promise.all([loadAdminReviewAnalysis(), loadAdminReviews()])
  } finally {
    loadingAdminReviews.value = false
  }
}

function mapReviewRow(item: ReviewRow): ReviewRow {
  return {
    id: Number(item.id),
    platform: item.platform,
    orderNo: item.orderNo,
    merchantName: item.merchantName,
    merchantAccountNo: item.merchantAccountNo || '',
    merchantPrimaryAccountNo: item.merchantPrimaryAccountNo || '',
    merchantPrimaryDisplayName: item.merchantPrimaryDisplayName || '',
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
  }
}

function ensureSelectedReviewMerchant() {
  const options = reviewMerchantOptions.value
  if (!options.length) {
    selectedReviewMerchantKey.value = ''
    return
  }
  if (!options.some((item) => item.value === selectedReviewMerchantKey.value)) {
    selectedReviewMerchantKey.value = options[0].value
  }
}

async function loadAfterSaleDisputes() {
  loadingAfterSaleDisputes.value = true
  try {
    const response = await fetch('http://localhost:8080/api/twenty-mall/admin/after-sales/disputes')
    const payload = await response.json()
    if (payload.code === '200' && Array.isArray(payload.data)) {
      afterSaleDisputes.value = payload.data.map((item: AfterSaleDisputeRow) => ({
        id: Number(item.id),
        afterSaleId: Number(item.afterSaleId || 0),
        orderNo: item.orderNo || '',
        afterSaleType: item.afterSaleType || '',
        afterSaleTypeText: afterSaleTypeText(item.afterSaleType),
        afterSaleStatus: item.afterSaleStatus || '',
        productName: item.productName || '',
        platformName: item.platformName || '',
        shopName: item.shopName || '',
        consumerPrimaryAccountNo: item.consumerPrimaryAccountNo || '',
        consumerPrimaryDisplayName: item.consumerPrimaryDisplayName || '',
        consumerPrimaryAvatar: item.consumerPrimaryAvatar || '',
        merchantPrimaryAccountNo: item.merchantPrimaryAccountNo || '',
        merchantPrimaryDisplayName: item.merchantPrimaryDisplayName || '',
        merchantPrimaryAvatar: item.merchantPrimaryAvatar || '',
        consumerReason: item.consumerReason || '',
        consumerEvidenceImages: Array.isArray(item.consumerEvidenceImages) ? item.consumerEvidenceImages : [],
        merchantEvidenceText: item.merchantEvidenceText || '',
        merchantEvidenceImages: Array.isArray(item.merchantEvidenceImages) ? item.merchantEvidenceImages : [],
        adminResult: item.adminResult || '',
        adminNote: item.adminNote || '',
        status: item.status || '待审核',
        createdAt: item.createdAt || '',
        updatedAt: item.updatedAt || ''
      }))
      return
    }
  } catch {
    // 页面保持空状态，避免展示不真实的模拟数据。
  } finally {
    loadingAfterSaleDisputes.value = false
  }
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
  resetAdminKnowledgeExtractor()
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
  articleKnowledgeExtracted.value = Boolean(row)
  articleEditorVisible.value = true
}

function openFaqEditor(row?: FaqRow) {
  resetAdminKnowledgeExtractor()
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
  faqKnowledgeExtracted.value = Boolean(row)
  faqEditorVisible.value = true
}

function resetAdminKnowledgeExtractor() {
  adminKnowledgeSourceText.value = ''
  selectedAdminKnowledgeFileName.value = ''
  extractingAdminKnowledge.value = false
  articleKnowledgeExtracted.value = false
  faqKnowledgeExtracted.value = false
}

async function handleAdminKnowledgeFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) {
    return
  }
  selectedAdminKnowledgeFileName.value = file.name
  try {
    adminKnowledgeSourceText.value = await readAdminKnowledgeFile(file)
    if (!adminKnowledgeSourceText.value.trim()) {
      ElMessage.warning('未能从文件中读取到文本内容，请改为复制文本后粘贴')
    }
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '文件读取失败，请改为复制文本后粘贴')
  } finally {
    input.value = ''
  }
}

async function readAdminKnowledgeFile(file: File) {
  const fileName = file.name.toLowerCase()
  if (fileName.endsWith('.pdf') || file.type === 'application/pdf') {
    return extractAdminPdfText(await file.arrayBuffer())
  }
  if (
    fileName.endsWith('.docx')
    || file.type === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ) {
    return extractAdminDocxText(await file.arrayBuffer())
  }
  return file.text()
}

async function extractAdminPdfText(buffer: ArrayBuffer) {
  const pdfjs = await import('pdfjs-dist/legacy/build/pdf.mjs')
  const documentTask = pdfjs.getDocument({ data: new Uint8Array(buffer), disableWorker: true } as Record<string, unknown>)
  const pdf = await documentTask.promise
  const pages: string[] = []
  for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
    const page = await pdf.getPage(pageNumber)
    const content = await page.getTextContent()
    pages.push(content.items.map((item) => ('str' in item ? item.str : '')).join(' '))
  }
  return pages.join('\n').trim()
}

async function extractAdminDocxText(buffer: ArrayBuffer) {
  const mammothModule = await import('mammoth/mammoth.browser')
  const mammoth = 'default' in mammothModule ? mammothModule.default : mammothModule
  const result = await mammoth.extractRawText({ arrayBuffer: buffer })
  return String(result.value || '').trim()
}

async function extractAdminKnowledge(target: 'article' | 'faq') {
  const source = adminKnowledgeSourceText.value.trim()
  if (!source) {
    ElMessage.warning('请先粘贴文本或选择文件')
    return
  }
  extractingAdminKnowledge.value = true
  const startedAt = Date.now()
  let logged = false
  try {
    const response = await fetch('http://localhost:9000/api/ai/knowledge/extract', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        text: source,
        knowledgeType: target === 'article' ? 'rules' : 'faq'
      })
    })
    const data = await response.json()
    if (!response.ok || !data) {
      recordAdminAiCallLog({
        businessType: target === 'article' ? 'KNOWLEDGE_ARTICLE' : 'KNOWLEDGE_FAQ',
        taskType: 'KNOWLEDGE_EXTRACTION',
        requestText: source,
        responseText: JSON.stringify(data || {}),
        success: false,
        errorMessage: data?.message || 'AI 识别失败',
        latencyMs: Date.now() - startedAt
      })
      logged = true
      throw new Error(data?.message || 'AI 识别失败')
    }
    if (target === 'article') {
      articleForm.value = {
        ...articleForm.value,
        title: String(data.title || '').trim(),
        content: String(data.content || '').trim(),
        category: mapAdminArticleCategory(String(data.category || '')),
        tagsJson: buildAdminKnowledgeTags(String(data.title || ''), String(data.category || '')),
        status: 'PUBLISHED',
        statusText: '已发布'
      }
      articleKnowledgeExtracted.value = true
    } else {
      faqForm.value = {
        ...faqForm.value,
        question: String(data.title || '').trim(),
        answer: String(data.content || '').trim(),
        category: mapAdminFaqCategory(String(data.category || '')),
        enabled: true
      }
      faqKnowledgeExtracted.value = true
    }
    recordAdminAiCallLog({
      businessType: target === 'article' ? 'KNOWLEDGE_ARTICLE' : 'KNOWLEDGE_FAQ',
      taskType: 'KNOWLEDGE_EXTRACTION',
      requestText: source,
      responseText: JSON.stringify(data),
      success: true,
      latencyMs: Date.now() - startedAt
    })
    logged = true
    ElMessage.success('AI 已识别，请确认内容后保存')
  } catch (error) {
    if (!logged) {
      recordAdminAiCallLog({
        businessType: target === 'article' ? 'KNOWLEDGE_ARTICLE' : 'KNOWLEDGE_FAQ',
        taskType: 'KNOWLEDGE_EXTRACTION',
        requestText: source,
        success: false,
        errorMessage: error instanceof Error ? error.message : 'AI 识别失败',
        latencyMs: Date.now() - startedAt
      })
    }
    ElMessage.error(error instanceof Error ? error.message : 'AI 识别失败，请确认 AI 服务已启动')
  } finally {
    extractingAdminKnowledge.value = false
  }
}

function recordAdminAiCallLog(payload: {
  businessType: string
  businessId?: number | null
  taskType: string
  requestText?: string
  responseText?: string
  success?: boolean
  errorMessage?: string
  latencyMs?: number
}) {
  fetch('http://localhost:8080/api/merchant/ai/call-log', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(payload)
  }).catch(() => undefined)
}

function mapAdminArticleCategory(category: string) {
  const map: Record<string, string> = {
    RETURN_REFUND: 'AFTER_SALE_POLICY',
    REFUND_ONLY: 'AFTER_SALE_POLICY',
    QUALITY_RETURN: 'AFTER_SALE_POLICY',
    REPAIR: 'AFTER_SALE_POLICY',
    PRICE_PROTECTION: 'AFTER_SALE_POLICY',
    FREIGHT_INSURANCE: 'AFTER_SALE_POLICY',
    LOGISTICS: 'PLATFORM_POLICY',
    PLATFORM_INTERVENTION: 'PLATFORM_POLICY',
    SPECIAL_GOODS: 'PRODUCT_POLICY',
    CUSTOMER_SERVICE: 'SERVICE_SCRIPT'
  }
  return map[category] || 'PLATFORM_POLICY'
}

function mapAdminFaqCategory(category: string) {
  const map: Record<string, string> = {
    REFUND_ONLY: 'REFUND',
    RETURN_REFUND: 'RETURN',
    EXCHANGE: 'AFTER_SALE',
    QUALITY_RETURN: 'AFTER_SALE',
    REPAIR: 'AFTER_SALE',
    PRICE_PROTECTION: 'AFTER_SALE',
    FREIGHT_INSURANCE: 'AFTER_SALE',
    PLATFORM_INTERVENTION: 'AFTER_SALE',
    CUSTOMER_SERVICE: 'ACCOUNT'
  }
  return map[category] || category || 'AFTER_SALE'
}

function buildAdminKnowledgeTags(title: string, category: string) {
  const tags = [title.slice(0, 8), category].filter(Boolean)
  return JSON.stringify(Array.from(new Set(tags)))
}

async function saveArticle() {
  if (!articleForm.value.id && !articleKnowledgeExtracted.value) {
    ElMessage.warning('请先上传文本或文件，并完成 AI 识别后再保存')
    return
  }
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
    recordAdminOperation(
      '知识库新增',
      articleForm.value.title,
      `${articleForm.value.id ? '编辑' : '新增'}知识文章，分类：${articleForm.value.category}`
    )
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
  if (!faqForm.value.id && !faqKnowledgeExtracted.value) {
    ElMessage.warning('请先上传文本或文件，并完成 AI 识别后再保存')
    return
  }
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
    recordAdminOperation(
      '知识库新增',
      faqForm.value.question,
      `${faqForm.value.id ? '编辑' : '新增'}常见问题，分类：${faqForm.value.category}`
    )
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
    recordAdminOperation(
      '规则配置',
      ruleForm.value.ruleName,
      `${ruleForm.value.id ? '编辑' : '新增'}售后规则，状态：${ruleForm.value.enabled ? '启用' : '停用'}`
    )
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
    recordAdminOperation(
      '规则配置',
      row.ruleName,
      `${row.enabled ? '启用' : '停用'}售后规则`
    )
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
    recordAdminOperation('规则配置', row.ruleName, '删除售后规则')
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
    recordAdminOperation(
      '评价异议处理',
      `订单 ${review.orderNo}`,
      `删除评价：${review.content.slice(0, 40)}${review.content.length > 40 ? '...' : ''}`
    )
    ElMessage.success('评价已删除')
    selectedReview.value = null
    await refreshReviewData()
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
    recordAdminOperation(
      '评价异议处理',
      `订单 ${review.orderNo}`,
      `${isApprove ? '通过评价异议并删除评价' : '拒绝评价异议并保留评价'}；说明：${adminNote}`
    )
    ElMessage.success(isApprove ? '异议已通过，评价已删除' : '异议已拒绝，评价保留')
    selectedReview.value = null
    await refreshReviewData()
    await loadOverview()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '评价异议审核失败')
  } finally {
    reviewingDispute.value = false
  }
}

function buildDisputeProductDetail(dispute: AfterSaleDisputeRow | null) {
  const rawName = dispute?.productName || '未知商品'
  const name = rawName.replace(/^万象商城\s*/, '').trim() || rawName
  const productMap = [
    {
      keyword: '钛杯',
      image: productCup,
      price: '￥129.00',
      description: '便携钛杯采用轻量杯身设计，适合通勤、露营和日常饮水使用，重点关注杯体密封性、容量标识和外观完整性。',
      policy: '支持质量问题退换货、仅退款审核、退货退款及平台介入；人为损坏或使用痕迹明显时需结合举证材料裁定。'
    },
    {
      keyword: '台灯',
      image: productLamp,
      price: '￥169.00',
      description: '北欧护眼台灯主打桌面照明和护眼场景，包含灯体、底座、电源线等组件，售后重点核验亮度、开关和外观破损情况。',
      policy: '支持7天无理由退货、质量问题退换货、运费险和平台介入；电器类商品需核验通电状态和配件完整性。'
    },
    {
      keyword: '键盘',
      image: productKeyboard,
      price: '￥239.00',
      description: '机械键盘类商品需关注按键触发、连接稳定性、轴体手感和外观磨损，适用于办公与游戏输入场景。',
      policy: '支持质量问题换修、退货退款和平台介入；影响二次销售的明显使用痕迹需结合双方凭证判断。'
    },
    {
      keyword: '背包',
      image: productBackpack,
      price: '￥199.00',
      description: '通勤背包类商品重点核验容量、拉链、肩带、面料瑕疵和防泼水能力，适用于日常通勤与短途出行。',
      policy: '支持7天无理由退货、质量问题退换货和运费险；吊牌缺失或严重污损需进入人工审核。'
    }
  ]
  const matched = productMap.find((item) => name.includes(item.keyword)) || productMap[0]
  return {
    name,
    image: matched.image,
    price: matched.price,
    description: matched.description,
    policy: matched.policy
  }
}

function disputeRefundAmountText(dispute: AfterSaleDisputeRow | null) {
  if (!dispute) {
    return ''
  }
  const amount = afterSaleDisputeRefundAmounts.value[dispute.id]
  if (amount) {
    return `￥${amount}`
  }
  const matched = dispute.adminNote?.match(/￥\s*(\d+(?:\.\d{1,2})?)/)
  return matched ? `￥${Number(matched[1]).toFixed(2)}` : ''
}

function disputeRemainingTime(dispute: AfterSaleDisputeRow | null) {
  if (!dispute) {
    return { text: '-', expired: false }
  }
  if (dispute.status !== '待审核') {
    return {
      text: dispute.adminNote?.includes('超时未处理') ? '已超时自动退款' : '已处理',
      expired: dispute.adminNote?.includes('超时未处理') || dispute.adminResult === '支持消费者'
    }
  }
  const createdTime = parseLocalTime(dispute.createdAt)
  if (!createdTime) {
    return { text: '24小时内处理', expired: false }
  }
  const deadline = createdTime.getTime() + 24 * 60 * 60 * 1000
  const remaining = deadline - Date.now()
  if (remaining <= 0) {
    return { text: '已超时，系统将自动退款', expired: true }
  }
  const hours = Math.floor(remaining / (60 * 60 * 1000))
  const minutes = Math.ceil((remaining % (60 * 60 * 1000)) / (60 * 1000))
  if (hours <= 0) {
    return { text: `剩余 ${minutes} 分钟`, expired: false }
  }
  return { text: `剩余 ${hours} 小时 ${minutes} 分钟`, expired: false }
}

function parseLocalTime(value: string) {
  if (!value) {
    return null
  }
  const normalized = value.replace(/\./g, '-').replace(/\//g, '-')
  const date = new Date(normalized)
  return Number.isNaN(date.getTime()) ? null : date
}

async function promptDisputeRefundAmount(dispute: AfterSaleDisputeRow) {
  const currentAmount = afterSaleDisputeRefundAmounts.value[dispute.id] || ''
  const result = await ElMessageBox.prompt(
    `请输入订单 ${dispute.orderNo} 本次平台裁定的部分退款金额，确认后将直接退还给消费者。`,
    '设置部分退款金额',
    {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      inputType: 'number',
      inputValue: currentAmount,
      inputPlaceholder: '请输入部分退款金额，例如 129.00',
      inputValidator: (value) => {
        const amount = Number(value)
        return (Number.isFinite(amount) && amount > 0) || '请输入大于 0 的部分退款金额'
      }
    }
  )
  const normalized = Number(result.value).toFixed(2)
  afterSaleDisputeRefundAmounts.value = {
    ...afterSaleDisputeRefundAmounts.value,
    [dispute.id]: normalized
  }
  return normalized
}

async function partialRefundAfterSaleDispute() {
  if (!selectedAfterSaleDispute.value) {
    return
  }
  const dispute = selectedAfterSaleDispute.value
  let refundAmount = ''
  let adminNote = ''
  try {
    refundAmount = await promptDisputeRefundAmount(dispute)
    const promptResult = await ElMessageBox.prompt(
      `确认对订单 ${dispute.orderNo} 执行部分退款 ￥${refundAmount} 吗？请填写平台处理说明。`,
      '部分退款',
      {
        confirmButtonText: '确认退款',
        cancelButtonText: '取消',
        inputType: 'textarea',
        inputPlaceholder: '例如：经平台核验，双方证据均有部分依据，裁定向消费者部分退款。',
        inputValidator: (value) => Boolean(value && value.trim()) || '请填写平台处理说明'
      }
    )
    adminNote = `部分退款金额：￥${refundAmount}。${promptResult.value.trim()}`
  } catch {
    // 用户取消输入时不提示错误。
    return
  }
  reviewingAfterSaleDispute.value = true
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/admin/after-sales/disputes/${dispute.id}/review`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ result: 'PARTIAL_REFUND', adminNote, refundAmount })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '部分退款处理失败')
    }
    recordAdminOperation(
      '争议订单处理',
      `订单 ${dispute.orderNo}`,
      `平台裁定部分退款 ￥${refundAmount}；说明：${adminNote}`
    )
    ElMessage.success(`已完成部分退款，金额 ￥${refundAmount} 已退还消费者`)
    selectedAfterSaleDispute.value = null
    await loadAfterSaleDisputes()
    await loadOverview()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '部分退款处理失败')
  } finally {
    reviewingAfterSaleDispute.value = false
  }
}

async function reviewAfterSaleDispute(result: 'SUPPORT_CONSUMER' | 'SUPPORT_MERCHANT') {
  if (!selectedAfterSaleDispute.value) {
    return
  }
  const dispute = selectedAfterSaleDispute.value
  const supportConsumer = result === 'SUPPORT_CONSUMER'
  let adminNote = ''
  try {
    const promptResult = await ElMessageBox.prompt(
      supportConsumer
        ? `确认支持消费者对订单 ${dispute.orderNo} 的平台介入申请吗？请填写处理说明。`
        : `确认支持商家对订单 ${dispute.orderNo} 的拒绝处理结果吗？请填写处理说明。`,
      supportConsumer ? '支持消费者' : '支持商家',
      {
        confirmButtonText: '确认处理',
        cancelButtonText: '取消',
        inputType: 'textarea',
        inputPlaceholder: supportConsumer
          ? '例如：经平台核验，商品问题证据充分，要求商家继续退款处理。'
          : '例如：经平台核验，商家拒绝依据充分，维持原处理结果。',
        inputValidator: (value) => Boolean(value && value.trim()) || '请填写平台处理说明'
      }
    )
    adminNote = promptResult.value.trim()
  } catch {
    return
  }
  reviewingAfterSaleDispute.value = true
  try {
    const response = await fetch(`http://localhost:8080/api/twenty-mall/admin/after-sales/disputes/${dispute.id}/review`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ result, adminNote })
    })
    const payload = await response.json()
    if (payload.code !== '200') {
      throw new Error(payload.message || '争议订单处理失败')
    }
    recordAdminOperation(
      '争议订单处理',
      `订单 ${dispute.orderNo}`,
      `${supportConsumer ? '支持消费者' : '支持商家'}；说明：${adminNote}`
    )
    ElMessage.success(supportConsumer ? '已支持消费者，售后将继续进入退款处理' : '已支持商家，维持商家拒绝结果')
    selectedAfterSaleDispute.value = null
    await loadAfterSaleDisputes()
    await loadOverview()
  } catch (error) {
    ElMessage.error(error instanceof Error ? error.message : '争议订单处理失败')
  } finally {
    reviewingAfterSaleDispute.value = false
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

function countBoundSecondary(rows: BindingRow[]) {
  return rows.filter((item) => Boolean(item.secondaryAccountNo)).length
}

function groupBindingsByPrimary(rows: BindingRow[]) {
  const map = new Map<string, BindingGroup>()
  rows.forEach((item) => {
    const key = item.primaryAccountNo || 'UNKNOWN'
    if (!map.has(key)) {
      map.set(key, {
        primaryAccountNo: item.primaryAccountNo,
        primaryDisplayName: item.primaryDisplayName,
        primaryAvatar: item.primaryAvatar,
        primaryBanStatus: item.primaryBanStatus || '正常',
        primaryBanDuration: item.primaryBanDuration || '',
        primaryBanUntil: item.primaryBanUntil || '',
        bindings: []
      })
    }
    const group = map.get(key)
    if (group) {
      if (!group.primaryAvatar && item.primaryAvatar) {
        group.primaryAvatar = item.primaryAvatar
      }
      if (!group.primaryDisplayName && item.primaryDisplayName) {
        group.primaryDisplayName = item.primaryDisplayName
      }
      if (item.primaryBanStatus === '已封禁') {
        group.primaryBanStatus = item.primaryBanStatus
        group.primaryBanDuration = item.primaryBanDuration || ''
        group.primaryBanUntil = item.primaryBanUntil || ''
      }
      if (item.secondaryAccountNo) {
        group.bindings.push(item)
      }
    }
  })
  return Array.from(map.values())
}

function platformIconByName(platformName: string) {
  if (platformName.includes('抖音')) {
    return douyinIcon
  }
  if (platformName.includes('淘宝')) {
    return taobaoIcon
  }
  if (platformName.includes('拼多多')) {
    return pddIcon
  }
  if (platformName.includes('京东')) {
    return jdIcon
  }
  if (platformName.includes('悦购集市')) {
    return yuegouMarketIcon
  }
  return twentyMallIcon
}

function platformStatusTagType(status: string) {
  if (status === '启用') {
    return 'success'
  }
  if (status === '规划中') {
    return 'warning'
  }
  return 'info'
}

function platformStatusDescription(status: string) {
  if (status === '启用') {
    return '已接入本地业务数据，可用于订单、售后和评价同步。'
  }
  if (status === '规划中') {
    return '已预留平台入口，等待后续开放平台能力接入。'
  }
  return '暂未接入真实开放平台，仅保留平台配置位置。'
}

function platformNextStep(platform: PlatformRow) {
  if (isSelfBuiltPlatform(platform.code)) {
    return `继续维护${platform.name}中的平台账号、订单、售后、评价和知识库数据，确保三端读取同一套业务数据。`
  }
  if (platform.status === '规划中') {
    return '后续需要补充开放平台授权、店铺绑定回调、订单同步、售后回写和评价同步等真实接口能力。'
  }
  return '当前平台尚未接入，建议先完成开放平台应用申请和接口权限配置后再启用。'
}

function isSelfBuiltPlatform(code: string) {
  return code === 'TWENTY_MALL' || code === 'YUEGOU_MARKET'
}

function syncProgress(count: number) {
  const maxCount = Math.max(1, ...syncOverview.value.map((item) => item.count))
  return Math.max(4, Math.round((count / maxCount) * 100))
}

function syncTaskDescription(task: string, count: number) {
  if (task.includes('订单')) {
    return `已从电商平台同步 ${formatNumber(count)} 条订单数据，用于消费者端订单列表、商家端售后处理和管理员统计。`
  }
  if (task.includes('售后')) {
    return `已同步 ${formatNumber(count)} 条售后记录，用于三端售后状态流转和争议处理。`
  }
  if (task.includes('评价')) {
    return `已同步 ${formatNumber(count)} 条评价数据，用于商家评价分析和管理员风险审核。`
  }
  return `当前任务已同步 ${formatNumber(count)} 条业务数据。`
}

function normalizeSyncTaskName(task = '') {
  return task.replace(/万象商城/g, '电商平台')
}

function parseTags(value: string) {
  if (!value) {
    return []
  }
  try {
    const parsed = JSON.parse(value)
    if (Array.isArray(parsed)) {
      return parsed.map((item) => String(item)).filter(Boolean).slice(0, 4)
    }
  } catch {
    return value
      .replace(/[[\]"']/g, '')
      .split(/[，,]/)
      .map((item) => item.trim())
      .filter(Boolean)
      .slice(0, 4)
  }
  return []
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

function afterSaleDisputeTagType(status?: string) {
  if (status === '待审核') {
    return 'warning'
  }
  if (status === '已处理') {
    return 'success'
  }
  return 'info'
}

function afterSaleTypeText(type?: string) {
  const map: Record<string, string> = {
    REFUND_ONLY: '仅退款',
    RETURN_REFUND: '退货退款',
    PRICE_PROTECTION: '价保',
    EXCHANGE: '换货'
  }
  return map[type || ''] || type || '未知类型'
}

function adminDisputeResultText(result?: string) {
  const map: Record<string, string> = {
    SUPPORT_CONSUMER: '支持消费者',
    SUPPORT_MERCHANT: '支持商家',
    PARTIAL_REFUND: '部分退款',
    支持消费者: '支持消费者',
    支持商家: '支持商家',
    部分退款: '部分退款'
  }
  return map[result || ''] || '暂无处理结果'
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
:global(.el-overlay) {
  background: rgba(15, 23, 42, 0.52) !important;
  backdrop-filter: blur(6px);
}

:global(.el-dialog) {
  overflow: hidden;
  border: 1px solid rgba(226, 232, 240, 0.96);
  border-radius: 18px !important;
  background: #ffffff;
  box-shadow: 0 28px 80px rgba(15, 23, 42, 0.24) !important;
}

:global(.el-dialog__header) {
  min-height: 62px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-right: 0 !important;
  padding: 20px 24px 16px !important;
  border-bottom: 1px solid #eef2f7;
  background:
    linear-gradient(135deg, rgba(239, 246, 255, 0.88), rgba(255, 255, 255, 0.96)),
    #fff;
  box-sizing: border-box;
}

:global(.el-dialog__title) {
  color: #0f172a;
  font-size: 20px;
  font-weight: 900;
  letter-spacing: 0;
}

:global(.el-dialog__headerbtn) {
  top: 16px !important;
  right: 18px !important;
  width: 34px !important;
  height: 34px !important;
  border-radius: 10px;
  transition: background 0.18s ease;
}

:global(.el-dialog__headerbtn:hover) {
  background: #f1f5f9;
}

:global(.el-dialog__body) {
  padding: 22px 24px !important;
  color: #334155;
}

:global(.el-dialog__footer) {
  padding: 16px 24px 22px !important;
  border-top: 1px solid #eef2f7;
  background: #fbfdff;
}

:global(.el-dialog__footer .el-button),
:global(.el-message-box__btns .el-button) {
  min-width: 92px;
  height: 38px;
  border-radius: 10px;
  font-weight: 800;
}

:global(.el-descriptions__label.el-descriptions__cell) {
  width: 132px;
  background: #f8fafc !important;
  color: #475569;
  font-weight: 800;
}

:global(.el-descriptions__content.el-descriptions__cell) {
  color: #0f172a;
  line-height: 1.65;
}

:global(.el-message-box) {
  width: min(520px, calc(100vw - 48px)) !important;
  overflow: hidden;
  border: 1px solid rgba(226, 232, 240, 0.96) !important;
  border-radius: 18px !important;
  box-shadow: 0 28px 80px rgba(15, 23, 42, 0.26) !important;
}

:global(.el-message-box__header) {
  padding: 22px 24px 12px !important;
}

:global(.el-message-box__title) {
  color: #0f172a;
  font-size: 20px !important;
  font-weight: 900;
}

:global(.el-message-box__content) {
  padding: 14px 24px 20px !important;
  color: #334155 !important;
  font-size: 15px;
  line-height: 1.75;
}

:global(.el-message-box__status) {
  width: 34px !important;
  height: 34px !important;
  display: inline-grid !important;
  place-items: center;
  border-radius: 50%;
  background: #fff7ed;
}

:global(.el-message-box__status.el-message-box-icon--warning) {
  color: #f59e0b !important;
}

:global(.el-message-box__message) {
  padding-left: 48px !important;
}

:global(.el-message-box__btns) {
  gap: 12px;
  padding: 0 24px 22px !important;
}

:global(.el-form-item__label) {
  color: #475569 !important;
  font-weight: 800;
}

:global(.el-input__wrapper),
:global(.el-textarea__inner) {
  border-radius: 10px !important;
  box-shadow: 0 0 0 1px #dbe3ef inset !important;
}

:global(.el-input__wrapper.is-focus),
:global(.el-textarea__inner:focus) {
  box-shadow: 0 0 0 1px #2563eb inset, 0 0 0 3px rgba(37, 99, 235, 0.12) !important;
}

.admin-login-page {
  min-height: 100vh;
  display: grid;
  grid-template-columns: minmax(420px, 0.94fr) minmax(430px, 0.72fr);
  align-items: center;
  justify-content: center;
  gap: 0;
  padding: 56px;
  box-sizing: border-box;
  background:
    linear-gradient(135deg, rgba(15, 23, 42, 0.96), rgba(19, 50, 96, 0.92)) left / 46% 100% no-repeat,
    linear-gradient(135deg, #f5f8ff 0%, #f8fafc 52%, #fff8ee 100%);
}

.admin-login-brand {
  position: relative;
  width: min(580px, 100%);
  min-height: 620px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 58px 54px;
  border-radius: 28px 0 0 28px;
  background:
    radial-gradient(circle at 18% 16%, rgba(96, 165, 250, 0.24), transparent 34%),
    linear-gradient(180deg, rgba(15, 23, 42, 0.2), rgba(15, 23, 42, 0.04));
  color: #fff;
  box-sizing: border-box;
  overflow: hidden;
}

.admin-login-brand::after {
  content: "";
  position: absolute;
  right: -90px;
  bottom: -110px;
  width: 300px;
  height: 300px;
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: 50%;
}

.admin-login-logo {
  width: 88px;
  height: 88px;
  display: grid;
  place-items: center;
  border-radius: 24px;
  background: rgba(255, 255, 255, 0.94);
  box-shadow: 0 22px 44px rgba(0, 0, 0, 0.18);
}

.admin-login-logo img {
  width: 72px;
  height: 72px;
  border-radius: 18px;
  object-fit: cover;
}

.admin-login-kicker {
  margin-top: 34px;
  color: #93c5fd;
  font-size: 12px;
  font-weight: 900;
  letter-spacing: 0.14em;
}

.admin-login-brand h1 {
  margin: 14px 0 14px;
  color: #fff;
  font-size: 46px;
  font-weight: 900;
  letter-spacing: 0;
}

.admin-login-brand p {
  margin: 0;
  max-width: 460px;
  color: #cbd5e1;
  font-size: 16px;
  line-height: 1.75;
}

.admin-login-features {
  display: grid;
  gap: 12px;
  width: min(440px, 100%);
  margin-top: 38px;
}

.admin-login-features div {
  padding: 15px 16px;
  border: 1px solid rgba(255, 255, 255, 0.13);
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(8px);
}

.admin-login-features strong,
.admin-login-features span {
  display: block;
}

.admin-login-features strong {
  color: #fff;
  font-size: 15px;
}

.admin-login-features span {
  margin-top: 6px;
  color: #b6c6dd;
  font-size: 13px;
}

.admin-login-card {
  width: min(480px, 100%);
  min-height: 620px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 46px;
  border: 1px solid rgba(226, 232, 240, 0.92);
  border-left: 0;
  border-radius: 0 28px 28px 0;
  background: rgba(255, 255, 255, 0.96);
  box-shadow: 0 32px 88px rgba(15, 23, 42, 0.16);
  backdrop-filter: blur(12px);
  box-sizing: border-box;
}

.admin-login-head span {
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 900;
  letter-spacing: 0.1em;
}

.admin-login-head h2 {
  margin: 10px 0 8px;
  color: #0f172a;
  font-size: 30px;
  font-weight: 900;
}

.admin-login-head p {
  margin: 0 0 26px;
  color: #64748b;
}

.admin-login-form :deep(.el-form-item__label) {
  color: #475569;
  font-weight: 800;
}

.admin-login-form :deep(.el-input__wrapper) {
  min-height: 48px;
  border-radius: 13px;
  box-shadow: 0 0 0 1px #dbe5f1 inset;
}

.admin-selector {
  width: 100%;
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}

.admin-selector button {
  height: 76px;
  border: 1px solid #dbe5f1;
  border-radius: 14px;
  background: #fff;
  color: #334155;
  cursor: pointer;
  transition: border-color 0.18s ease, box-shadow 0.18s ease, transform 0.18s ease, background 0.18s ease;
}

.admin-selector button:hover {
  border-color: #93c5fd;
  transform: translateY(-1px);
}

.admin-selector button.active {
  border-color: #2563eb;
  background: #eff6ff;
  box-shadow: 0 10px 22px rgba(37, 99, 235, 0.14);
}

.admin-selector button img,
.admin-selector button strong {
  display: block;
}

.admin-selector button img {
  width: 40px;
  height: 40px;
  margin: 0 auto 7px;
  border-radius: 14px;
  object-fit: cover;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.1);
}

.admin-selector button.active img {
  box-shadow: 0 10px 20px rgba(37, 99, 235, 0.22);
}

.admin-selector button strong {
  color: #0f172a;
  font-size: 13px;
}

.admin-login-submit {
  width: 100%;
  height: 48px;
  border-radius: 13px;
  font-weight: 900;
  box-shadow: 0 14px 26px rgba(37, 99, 235, 0.22);
}

.admin-login-modules {
  margin-top: 24px;
  padding: 18px;
  border: 1px solid #dbeafe;
  border-radius: 16px;
  background: linear-gradient(180deg, #f8fbff 0%, #ffffff 100%);
  box-shadow: 0 12px 28px rgba(37, 99, 235, 0.08);
}

.admin-login-modules strong {
  display: block;
  color: #0f172a;
  font-size: 14px;
  font-weight: 900;
}

.admin-login-modules div {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin-top: 12px;
}

.admin-login-modules span {
  padding: 10px 12px;
  border-radius: 12px;
  background: #fff;
  color: #475569;
  font-size: 12px;
  font-weight: 800;
}

.header-actions,
.admin-session {
  display: flex;
  align-items: center;
  gap: 12px;
}

.admin-session {
  padding: 5px 5px 5px 12px;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  background: #f8fafc;
}

.admin-session img {
  width: 26px;
  height: 26px;
  margin-left: -5px;
  border-radius: 9px;
  object-fit: cover;
}

.admin-session span {
  color: #334155;
  font-size: 13px;
  font-weight: 800;
}

@media (max-width: 980px) {
  .admin-login-page {
    grid-template-columns: 1fr;
    padding: 24px;
    background: linear-gradient(135deg, #f5f8ff 0%, #f8fafc 52%, #fff8ee 100%);
  }

  .admin-login-brand,
  .admin-login-card {
    width: min(560px, 100%);
    min-height: auto;
    justify-self: center;
    border-radius: 24px;
  }

  .admin-login-brand {
    padding: 34px;
  }

  .admin-login-card {
    padding: 34px;
    border-left: 1px solid rgba(226, 232, 240, 0.92);
  }
}

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

.external-platform-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.platform-overview-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.platform-overview-card {
  min-height: 96px;
}

.platform-overview-card span,
.platform-overview-card em {
  display: block;
  color: #64748b;
  font-size: 13px;
}

.platform-overview-card strong {
  margin-top: 8px;
  color: #0f172a;
  font-size: 30px;
  line-height: 1;
}

.platform-overview-card em {
  margin-top: 8px;
  font-style: normal;
}

.platform-card-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.platform-access-card {
  display: flex;
  min-height: 220px;
  flex-direction: column;
  gap: 14px;
}

.platform-access-head {
  display: grid;
  grid-template-columns: 56px minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
}

.platform-large-icon {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  object-fit: cover;
  background: #eef2f7;
}

.platform-access-head strong,
.platform-access-head span {
  display: block;
}

.platform-access-head strong {
  color: #0f172a;
  font-size: 17px;
}

.platform-access-head span {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
}

.platform-access-card p {
  min-height: 44px;
  margin: 0;
  color: #475569;
  font-size: 14px;
  line-height: 1.6;
}

.platform-access-meta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.platform-access-meta div {
  padding: 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.platform-access-meta span,
.platform-access-meta strong {
  display: block;
}

.platform-access-meta span {
  color: #64748b;
  font-size: 12px;
}

.platform-access-meta strong {
  margin-top: 6px;
  color: #0f172a;
  font-size: 18px;
}

.platform-access-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px solid #eef2f7;
}

.platform-access-footer span {
  color: #64748b;
  font-size: 13px;
}

.platform-dialog-head {
  display: grid;
  grid-template-columns: 56px minmax(0, 1fr) auto;
  align-items: center;
  gap: 12px;
  margin-bottom: 16px;
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.platform-dialog-head strong,
.platform-dialog-head span {
  display: block;
}

.platform-dialog-head strong {
  color: #0f172a;
  font-size: 17px;
}

.platform-dialog-head span {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
}

.platform-config-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
  margin-bottom: 16px;
}

.platform-config-grid div {
  padding: 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.platform-config-grid span,
.platform-config-grid strong {
  display: block;
}

.platform-config-grid span {
  color: #64748b;
  font-size: 12px;
}

.platform-config-grid strong {
  margin-top: 6px;
  color: #0f172a;
  font-size: 14px;
}

.platform-config-section {
  margin-top: 12px;
  padding: 12px 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.platform-config-section h3 {
  margin: 0 0 8px;
  color: #0f172a;
  font-size: 15px;
}

.platform-config-section p {
  margin: 0;
  color: #475569;
  font-size: 14px;
  line-height: 1.7;
}

.sync-monitor-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.sync-metric-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.sync-metric-card {
  min-height: 96px;
}

.sync-metric-card span,
.sync-metric-card em {
  display: block;
  color: #64748b;
  font-size: 13px;
}

.sync-metric-card strong {
  margin-top: 8px;
  color: #0f172a;
  font-size: 24px;
  line-height: 1.2;
}

.sync-metric-card em {
  margin-top: 8px;
  font-style: normal;
}

.sync-card-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
}

.sync-task-card {
  display: flex;
  min-height: 220px;
  flex-direction: column;
  gap: 14px;
}

.sync-task-head,
.sync-task-footer,
.sync-dialog-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.sync-task-head strong,
.sync-task-head span {
  display: block;
}

.sync-task-head strong {
  color: #0f172a;
  font-size: 16px;
}

.sync-task-head span {
  margin-top: 5px;
  color: #64748b;
  font-size: 12px;
}

.sync-task-value {
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.sync-task-value span,
.sync-task-value strong {
  display: block;
}

.sync-task-value span {
  color: #64748b;
  font-size: 13px;
}

.sync-task-value strong {
  margin-top: 6px;
  color: #0f172a;
  font-size: 28px;
  line-height: 1;
}

.sync-task-footer {
  margin-top: auto;
  padding-top: 12px;
  border-top: 1px solid #eef2f7;
}

.sync-task-footer span {
  color: #64748b;
  font-size: 13px;
  line-height: 1.5;
}

.sync-detail-panel {
  padding-bottom: 12px;
}

.sync-dialog-title {
  margin-bottom: 16px;
}

.sync-dialog-title strong {
  color: #0f172a;
  font-size: 17px;
}

.knowledge-workbench {
  padding: 0;
  overflow: hidden;
}

.knowledge-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 20px;
  border-bottom: 1px solid #e5e7eb;
  background: #f8fafc;
}

.knowledge-head h2 {
  margin: 0;
  color: #0f172a;
  font-size: 20px;
}

.knowledge-head p {
  margin: 6px 0 0;
  color: #64748b;
  font-size: 13px;
}

.knowledge-filter-bar {
  display: grid;
  grid-template-columns: minmax(320px, 1fr) 180px;
  gap: 12px;
  padding: 14px 20px 4px;
}

.knowledge-workbench :deep(.el-tabs__header) {
  margin: 0 20px 12px;
}

.knowledge-card-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0 20px 20px;
}

.knowledge-item-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 210px;
  gap: 16px;
  padding: 16px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.knowledge-item-card:hover {
  background: #f8fbff;
  border-color: #bfdbfe;
}

.knowledge-item-main {
  min-width: 0;
}

.knowledge-item-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.knowledge-item-title strong {
  overflow: hidden;
  color: #0f172a;
  font-size: 16px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.knowledge-item-main p {
  display: -webkit-box;
  margin: 10px 0;
  overflow: hidden;
  color: #475569;
  font-size: 14px;
  line-height: 1.7;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 2;
}

.knowledge-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.knowledge-item-side {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  justify-content: space-between;
  gap: 12px;
  border-left: 1px solid #eef2f7;
  padding-left: 16px;
  text-align: right;
}

.knowledge-item-side span {
  color: #64748b;
  font-size: 12px;
}

.knowledge-item-side strong {
  display: block;
  margin-top: 4px;
  color: #0f172a;
  font-size: 13px;
}

.ai-knowledge-source {
  margin-bottom: 16px;
  padding: 14px;
  border: 1px solid #dbeafe;
  border-radius: 8px;
  background: #f8fbff;
}

.ai-source-head,
.ai-source-actions {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
}

.ai-source-head {
  margin-bottom: 12px;
}

.ai-source-head strong,
.ai-source-head span {
  display: block;
}

.ai-source-head strong {
  color: #0f172a;
  font-size: 15px;
}

.ai-source-head span,
.ai-source-actions span {
  margin-top: 4px;
  color: #64748b;
  font-size: 12px;
}

.ai-source-actions {
  margin-top: 12px;
}

.file-picker {
  position: relative;
  display: inline-flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  height: 32px;
  padding: 0 12px;
  border: 1px solid #409eff;
  border-radius: 6px;
  color: #1677ff;
  font-size: 13px;
  cursor: pointer;
}

.file-picker input {
  position: absolute;
  inset: 0;
  opacity: 0;
  cursor: pointer;
}

.rule-workbench {
  padding: 0;
  overflow: hidden;
}

.rule-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 20px;
  border-bottom: 1px solid #e5e7eb;
  background: #f8fafc;
}

.rule-head h2 {
  margin: 0;
  color: #0f172a;
  font-size: 20px;
}

.rule-head p {
  margin: 6px 0 0;
  color: #64748b;
  font-size: 13px;
}

.rule-filter-bar {
  display: grid;
  grid-template-columns: minmax(320px, 1fr) 180px 150px;
  gap: 12px;
  padding: 14px 20px;
}

.rule-card-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0 20px 20px;
}

.rule-item-card {
  padding: 16px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.rule-item-card:hover {
  background: #f8fbff;
  border-color: #bfdbfe;
}

.rule-item-top,
.rule-item-footer,
.rule-item-status {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.rule-item-top strong,
.rule-item-top span {
  display: block;
}

.rule-item-top strong {
  color: #0f172a;
  font-size: 16px;
}

.rule-item-top span {
  margin-top: 6px;
  color: #64748b;
  font-size: 13px;
}

.rule-flow {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
  margin: 14px 0;
}

.rule-flow div {
  padding: 12px 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.rule-flow span {
  color: #64748b;
  font-size: 12px;
}

.rule-flow p {
  margin: 7px 0 0;
  color: #0f172a;
  font-size: 14px;
  line-height: 1.6;
}

.rule-item-footer {
  padding-top: 12px;
  border-top: 1px solid #eef2f7;
  color: #64748b;
  font-size: 13px;
}

.dispute-workbench {
  padding: 0;
  overflow: hidden;
}

.dispute-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
  padding: 18px 20px;
  border-bottom: 1px solid #e5e7eb;
  background: #f8fafc;
}

.dispute-head h2 {
  margin: 0;
  color: #0f172a;
  font-size: 20px;
}

.dispute-head p {
  margin: 6px 0 0;
  color: #64748b;
  font-size: 13px;
}

.dispute-filter-bar {
  display: grid;
  grid-template-columns: minmax(320px, 1fr) 160px;
  gap: 12px;
  padding: 14px 20px;
}

.dispute-card-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0 20px 20px;
}

.dispute-item-card {
  padding: 16px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.dispute-item-card:hover {
  background: #f8fbff;
  border-color: #bfdbfe;
}

.dispute-item-top,
.dispute-item-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.dispute-item-top strong,
.dispute-item-top span {
  display: block;
}

.dispute-item-top strong {
  color: #0f172a;
  font-size: 17px;
}

.dispute-item-top span {
  margin-top: 5px;
  color: #64748b;
  font-size: 13px;
}

.dispute-product-line {
  display: grid;
  grid-template-columns: minmax(180px, 1fr) 120px 150px 160px 160px;
  gap: 12px;
  margin: 14px 0;
}

.dispute-product-line div,
.dispute-detail-grid div,
.platform-decision-card {
  padding: 12px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.dispute-product-line span,
.dispute-product-line strong,
.dispute-detail-grid span,
.dispute-detail-grid strong,
.platform-decision-card span,
.platform-decision-card strong {
  display: block;
}

.dispute-product-line span,
.dispute-detail-grid span,
.platform-decision-card span {
  color: #64748b;
  font-size: 12px;
}

.dispute-product-line strong,
.dispute-detail-grid strong,
.platform-decision-card strong {
  margin-top: 6px;
  color: #0f172a;
  font-size: 14px;
}

.danger-text {
  color: #dc2626 !important;
}

.dispute-reason-grid,
.dispute-evidence-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.dispute-reason-grid div,
.dispute-evidence-card {
  padding: 12px 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.dispute-reason-grid span {
  color: #64748b;
  font-size: 12px;
}

.dispute-reason-grid p,
.dispute-evidence-card p,
.platform-decision-card p {
  margin: 7px 0 0;
  color: #334155;
  font-size: 14px;
  line-height: 1.7;
}

.dispute-item-footer {
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid #eef2f7;
  color: #64748b;
  font-size: 13px;
}

.dispute-detail {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.dispute-detail-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.dispute-detail-head strong,
.dispute-detail-head span {
  display: block;
}

.dispute-detail-head strong {
  color: #0f172a;
  font-size: 18px;
}

.dispute-detail-head span {
  margin-top: 5px;
  color: #64748b;
  font-size: 13px;
}

.dispute-account-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.dispute-account-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
}

.dispute-account-card span,
.dispute-account-card strong,
.dispute-account-card em {
  display: block;
}

.dispute-account-card span {
  color: #64748b;
  font-size: 12px;
  font-weight: 700;
}

.dispute-account-card strong {
  margin-top: 4px;
  color: #0f172a;
  font-size: 16px;
  font-weight: 900;
}

.dispute-account-card em {
  margin-top: 3px;
  color: #64748b;
  font-size: 13px;
  font-style: normal;
  font-weight: 700;
}

.dispute-detail-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}

.dispute-product-cell {
  position: relative;
}

.dispute-product-cell .el-button {
  position: absolute;
  right: 10px;
  top: 9px;
  padding: 0;
}

.dispute-evidence-card h3 {
  margin: 0 0 8px;
  color: #0f172a;
  font-size: 15px;
}

.empty-evidence {
  display: inline-block;
  margin-top: 10px;
  color: #94a3b8;
  font-size: 13px;
}

.platform-decision-card {
  display: grid;
  grid-template-columns: 160px 160px minmax(0, 1fr);
  gap: 12px;
  align-items: start;
}

.platform-decision-card p {
  margin: 0;
}

.product-detail-panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.product-detail-main {
  display: grid;
  grid-template-columns: 180px minmax(0, 1fr);
  gap: 18px;
  align-items: center;
  padding: 16px;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  background: #f8fafc;
}

.product-detail-main img {
  width: 180px;
  height: 180px;
  object-fit: cover;
  border-radius: 10px;
  background: #eef2f7;
}

.product-detail-main span {
  display: block;
  color: #64748b;
  font-size: 13px;
}

.product-detail-main h3 {
  margin: 8px 0 10px;
  color: #0f172a;
  font-size: 22px;
}

.product-detail-main strong {
  display: block;
  color: #ef4444;
  font-size: 20px;
}

.product-detail-main p {
  margin: 12px 0 0;
  color: #334155;
  font-size: 14px;
  line-height: 1.7;
}

.product-detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.product-detail-grid div {
  padding: 12px 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.product-detail-grid span,
.product-detail-grid strong {
  display: block;
}

.product-detail-grid span {
  color: #64748b;
  font-size: 12px;
}

.product-detail-grid strong {
  margin-top: 7px;
  color: #0f172a;
  font-size: 14px;
  line-height: 1.6;
}

.user-management-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.user-metrics {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.user-metric {
  min-height: 96px;
}

.user-metric span,
.user-metric em {
  display: block;
  color: #64748b;
  font-size: 13px;
}

.user-metric strong {
  margin-top: 8px;
  color: #0f172a;
  font-size: 30px;
  line-height: 1;
}

.user-metric em {
  margin-top: 8px;
  font-style: normal;
}

.user-filter-card {
  display: grid;
  grid-template-columns: minmax(320px, 1fr) 180px;
  gap: 12px;
  padding: 14px 16px;
}

.user-group-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.user-group-card {
  padding: 0;
  overflow: hidden;
}

.user-group-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 16px 18px;
  border-bottom: 1px solid #e5e7eb;
  background: #f8fafc;
}

.user-profile-cell,
.dialog-user-head {
  display: flex;
  align-items: center;
  gap: 12px;
  min-width: 0;
}

.user-profile-cell strong,
.user-profile-cell span,
.dialog-user-head strong,
.dialog-user-head span {
  display: block;
}

.user-profile-cell strong,
.dialog-user-head strong {
  color: #0f172a;
  font-size: 16px;
}

.user-profile-cell span,
.dialog-user-head span {
  margin-top: 4px;
  color: #64748b;
  font-size: 13px;
}

.user-group-meta {
  display: flex;
  align-items: center;
  gap: 10px;
}

.binding-row-list {
  display: flex;
  flex-direction: column;
}

.binding-row-card {
  display: grid;
  grid-template-columns: 150px minmax(140px, 0.8fr) minmax(200px, 1fr) 180px;
  align-items: center;
  gap: 16px;
  padding: 14px 18px;
  border-bottom: 1px solid #eef2f7;
}

.binding-row-card:last-child {
  border-bottom: 0;
}

.binding-empty-row {
  padding: 18px;
  border-top: 1px solid #eef2f7;
  color: #94a3b8;
  font-size: 13px;
  font-weight: 700;
  text-align: center;
}

.merchant-binding-card {
  grid-template-columns: 150px minmax(140px, 0.8fr) minmax(220px, 1.1fr) 180px;
}

.binding-row-card strong {
  display: block;
  margin: 4px 0 0;
  overflow: hidden;
  color: #0f172a;
  font-size: 14px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.binding-label {
  color: #64748b;
  font-size: 12px;
}

.dialog-user-head {
  margin-bottom: 16px;
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.dialog-account-actions {
  margin-left: auto;
}

.ban-dialog :deep(.el-dialog) {
  border-radius: 18px;
  overflow: hidden;
}

.ban-dialog :deep(.el-dialog__header) {
  display: none;
}

.ban-dialog :deep(.el-dialog__body) {
  padding: 0;
}

.ban-dialog :deep(.el-dialog__footer) {
  padding: 16px 22px 20px;
  border-top: 1px solid #eef2f7;
}

.ban-dialog-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 18px;
  padding: 24px 24px 18px;
  border-bottom: 1px solid #eef2f7;
  background: linear-gradient(135deg, #fff7ed 0%, #fff 62%, #f8fbff 100%);
}

.ban-dialog-head span {
  color: #dc2626;
  font-size: 12px;
  font-weight: 900;
  letter-spacing: 0.1em;
}

.ban-dialog-head h2 {
  margin: 8px 0;
  color: #0f172a;
  font-size: 24px;
  font-weight: 900;
}

.ban-dialog-head p {
  margin: 0;
  max-width: 360px;
  color: #64748b;
  font-size: 13px;
  line-height: 1.65;
}

.ban-dialog-close {
  width: 32px;
  height: 32px;
  border: 1px solid #e5e7eb;
  border-radius: 999px;
  background: #fff;
  color: #94a3b8;
  cursor: pointer;
  font-size: 22px;
  line-height: 1;
}

.ban-account-card {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 14px;
  margin: 20px 24px 14px;
  padding: 16px;
  border: 1px solid #e7eef8;
  border-radius: 14px;
  background: #f8fafc;
}

.ban-account-card strong,
.ban-account-card span {
  display: block;
}

.ban-account-card strong {
  color: #0f172a;
  font-size: 16px;
}

.ban-account-card span {
  margin-top: 5px;
  color: #64748b;
  font-size: 13px;
}

.ban-current-status {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin: 0 24px 14px;
  padding: 10px 12px;
  border: 1px solid #fecaca;
  border-radius: 12px;
  background: #fff1f2;
  color: #991b1b;
  font-size: 13px;
}

.ban-duration-panel {
  margin: 0 24px 22px;
}

.ban-section-title {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
}

.ban-section-title strong {
  color: #0f172a;
  font-size: 15px;
}

.ban-section-title span {
  color: #94a3b8;
  font-size: 12px;
}

.ban-duration-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
}

.ban-duration-grid button {
  height: 42px;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  background: #fff;
  color: #334155;
  cursor: pointer;
  font-size: 14px;
  font-weight: 800;
}

.ban-duration-grid button:hover {
  border-color: #fca5a5;
  color: #dc2626;
}

.ban-duration-grid button.active {
  border-color: #ef4444;
  background: #fff1f2;
  color: #dc2626;
  box-shadow: 0 8px 18px rgba(239, 68, 68, 0.12);
}

.operation-log-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.operation-log-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
}

.operation-log-toolbar h2 {
  margin: 0;
  color: #0f172a;
  font-size: 22px;
}

.operation-log-toolbar p {
  margin: 8px 0 0;
  color: #64748b;
  font-size: 13px;
}

.operation-log-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.operation-log-card {
  padding: 16px;
}

.operation-admin-cell {
  display: flex;
  align-items: center;
  gap: 9px;
}

.operation-admin-cell img {
  width: 28px;
  height: 28px;
  border-radius: 9px;
  object-fit: cover;
}

.operation-admin-cell span {
  color: #0f172a;
  font-weight: 800;
}

.review-page,
.knowledge-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.review-stats,
.rule-stats,
.knowledge-stats,
.dispute-stats {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 16px;
}

.review-stat,
.rule-stat,
.knowledge-stat,
.dispute-stat {
  min-height: 96px;
}

.review-stat span,
.rule-stat span,
.knowledge-stat span,
.dispute-stat span,
.knowledge-stat em,
.rule-stat em,
.dispute-stat em {
  display: block;
  color: #64748b;
  font-size: 14px;
}

.knowledge-stat em,
.rule-stat em,
.dispute-stat em {
  margin-top: 8px;
  font-size: 13px;
  font-style: normal;
}

.review-stat strong,
.rule-stat strong,
.knowledge-stat strong,
.dispute-stat strong {
  display: block;
  margin-top: 12px;
  color: #0f172a;
  font-size: 28px;
}

.admin-review-page {
  gap: 18px;
}

.admin-review-hero {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 24px;
  overflow: hidden;
  border: 1px solid #dbeafe;
  background:
    linear-gradient(135deg, rgba(239, 246, 255, 0.96), rgba(255, 255, 255, 0.98)),
    #fff;
}

.section-eyebrow {
  display: inline-flex;
  margin-bottom: 8px;
  color: #2563eb;
  font-size: 13px;
  font-weight: 700;
}

.admin-review-hero h2 {
  margin: 0;
  color: #0f172a;
  font-size: 26px;
}

.admin-review-hero p {
  max-width: 620px;
  margin: 10px 0 0;
  color: #64748b;
  font-size: 14px;
  line-height: 1.7;
}

.admin-review-merchant-switch {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  margin-top: 16px;
  padding: 8px 10px 8px 14px;
  border: 1px solid #dbeafe;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.82);
}

.admin-review-merchant-switch span {
  color: #475569;
  font-size: 13px;
  font-weight: 800;
  white-space: nowrap;
}

.admin-review-hero-side {
  min-width: 180px;
  max-width: 320px;
  padding: 18px 20px;
  border: 1px solid #bfdbfe;
  border-radius: 8px;
  background: #fff;
  text-align: right;
}

.admin-review-hero-side strong,
.admin-review-hero-side span,
.admin-review-stat em {
  display: block;
}

.admin-review-hero-side strong {
  color: #1d4ed8;
  font-size: 24px;
}

.admin-review-hero-side span {
  margin-top: 6px;
  color: #64748b;
  font-size: 13px;
  line-height: 1.5;
}

.admin-review-stat {
  position: relative;
  border: 1px solid #e2e8f0;
}

.admin-review-stat em {
  margin-top: 8px;
  color: #94a3b8;
  font-size: 12px;
  font-style: normal;
}

.admin-review-insights {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.review-insight-card {
  min-height: 210px;
}

.review-insight-card .panel-title p,
.admin-review-list-head p {
  margin: 5px 0 0;
  color: #64748b;
  font-size: 13px;
}

.review-chip-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.review-chip-row {
  position: relative;
  display: grid;
  grid-template-columns: 88px 56px minmax(120px, 1fr);
  align-items: center;
  gap: 12px;
  color: #334155;
  font-size: 14px;
}

.review-chip-row strong {
  color: #0f172a;
}

.review-chip-row em {
  display: block;
  height: 8px;
  border-radius: 999px;
  background: linear-gradient(90deg, #2563eb, #38bdf8);
}

.admin-review-list {
  padding-bottom: 18px;
}

.admin-review-cards {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.admin-review-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 160px;
  gap: 18px;
  padding: 16px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.admin-review-title-line,
.admin-review-meta,
.admin-review-action {
  display: flex;
  align-items: center;
}

.admin-review-title-line {
  justify-content: space-between;
  gap: 12px;
}

.admin-review-title-line strong {
  overflow: hidden;
  color: #0f172a;
  font-size: 16px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.admin-review-tags,
.admin-review-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.admin-review-content {
  margin: 10px 0;
  color: #334155;
  font-size: 14px;
  line-height: 1.7;
}

.admin-review-meta span {
  color: #64748b;
  font-size: 12px;
}

.admin-review-action {
  flex-direction: column;
  justify-content: center;
  gap: 12px;
  border-left: 1px solid #e5e7eb;
}

.evidence-list {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.evidence-image {
  width: 88px;
  height: 88px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
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

.ai-console-card {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.ai-console-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding-bottom: 16px;
  border-bottom: 1px solid #e5e7eb;
}

.ai-provider-card {
  display: flex;
  align-items: center;
  gap: 16px;
}

.deepseek-logo {
  width: 176px;
  height: 52px;
  border-radius: 12px;
  object-fit: contain;
  background: #f5f8ff;
}

.ai-provider-card strong,
.ai-provider-card span {
  display: block;
}

.ai-provider-card strong {
  color: #0f172a;
  font-size: 22px;
}

.ai-provider-card span {
  margin-top: 6px;
  color: #64748b;
  font-size: 13px;
}

.ai-status-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
}

.ai-status-card {
  min-height: 104px;
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.ai-status-card span,
.ai-status-card strong,
.ai-status-card em {
  display: block;
}

.ai-status-card span {
  color: #64748b;
  font-size: 13px;
}

.ai-status-card strong {
  margin-top: 8px;
  color: #0f172a;
  font-size: 24px;
  line-height: 1.1;
}

.ai-status-card em {
  margin-top: 8px;
  color: #64748b;
  font-size: 12px;
  font-style: normal;
}

.ai-key-edit-btn {
  margin-top: 14px;
}

.ai-key-editor {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.ai-key-warning {
  padding: 13px 14px;
  border: 1px solid #bfdbfe;
  border-radius: 10px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 13px;
  line-height: 1.7;
}

.ai-key-meta {
  display: grid;
  grid-template-columns: 90px minmax(0, 1fr);
  gap: 10px 14px;
  padding: 14px;
  border: 1px solid #e5e7eb;
  border-radius: 10px;
  background: #f8fafc;
}

.ai-key-meta span {
  color: #64748b;
  font-size: 13px;
}

.ai-key-meta strong {
  overflow: hidden;
  color: #0f172a;
  font-size: 14px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status-ok {
  color: #16a34a !important;
}

.status-warning {
  color: #d97706 !important;
}

.status-danger {
  color: #dc2626 !important;
}

.ai-config-grid {
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(0, 0.9fr);
  gap: 16px;
}

.ai-info-panel {
  padding: 16px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.ai-info-panel h3 {
  margin: 0 0 14px;
  color: #0f172a;
  font-size: 16px;
}

.ai-info-row {
  display: grid;
  grid-template-columns: 110px minmax(0, 1fr);
  gap: 12px;
  padding: 11px 0;
  border-bottom: 1px solid #eef2f7;
}

.ai-info-row:last-child {
  border-bottom: 0;
}

.ai-info-row span,
.ai-policy-box span {
  color: #64748b;
  font-size: 13px;
}

.ai-info-row strong {
  overflow: hidden;
  color: #0f172a;
  font-size: 14px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.ai-policy-box {
  padding: 12px 14px;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #f8fafc;
}

.ai-policy-box + .ai-policy-box {
  margin-top: 10px;
}

.ai-policy-box p {
  margin: 7px 0 0;
  color: #0f172a;
  font-size: 15px;
  font-weight: 700;
}

.ai-policy-note {
  margin-top: 12px;
  padding: 12px 14px;
  border-radius: 8px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 13px;
  line-height: 1.7;
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
