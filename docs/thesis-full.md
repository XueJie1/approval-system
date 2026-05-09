# 基于 Flowable 工作流引擎的智能协同审批系统设计与实现

**学校:** [学校名称]
**专业:** 计算机科学与技术
**指导教师:** [导师姓名]
**日期:** 二零二六年五月

---

## 摘要

随着企业数字化转型的深入推进，传统纸质审批和邮件审批方式已难以满足现代企业对运营效率和管理规范化的要求。审批流程作为企业日常管理中的核心环节，其自动化、智能化水平直接影响着企业的决策效率和风险管控能力。本文设计并实现了一个基于 Flowable 工作流引擎的智能协同审批系统，该系统融合了 BPMN 2.0 工作流标准、动态表单技术和人工智能大语言模型辅助决策能力，为企业提供了一套完整的审批管理解决方案。

系统后端采用 Spring Boot 3.5 框架和 Flowable 7.0 工作流引擎，前端基于 Vue 3 和 TypeScript 构建，数据持久化使用 MariaDB 数据库与 Spring Data JPA 框架。在安全方面，系统实现了基于 JWT 的无状态认证、基于 RBAC 的细粒度权限控制以及基于 TOTP 的双因素认证。系统支持的审批模式包括单人审批、顺序审批、并行会签和或签四种类型，同时提供了任务委派、转办、回退等灵活的任务流转机制。在智能化方面，系统集成了大语言模型能力，能够在审批任务中自动生成审批建议、风险提示和参考摘要，并支持通过自然语言输入实现表单的智能填充。

系统已在开发环境中完成功能验证，测试结果表明系统在审批流程管理、动态表单配置、AI 辅助决策等方面均达到了预期设计目标，能够有效提升企业审批管理的效率和规范性。

**关键词:** Java 语言; Flowable 工作流引擎; 审批系统; Spring Boot; LLM 智能辅助

## ABSTRACT

With the deepening of enterprise digital transformation, traditional paper-based and email-based approval methods can no longer meet the requirements of modern enterprises for operational efficiency and management standardization. As a core component of daily enterprise management, the automation and intelligence level of approval processes directly affects decision-making efficiency and risk control capabilities. This paper designs and implements an intelligent collaborative approval system based on the Flowable workflow engine, which integrates BPMN 2.0 workflow standards, dynamic form technology, and large language model-assisted decision-making capabilities, providing a complete approval management solution for enterprises.

The backend of the system adopts the Spring Boot 3.5 framework and Flowable 7.0 workflow engine, while the frontend is built on Vue 3 and TypeScript. Data persistence uses MariaDB database with Spring Data JPA framework. In terms of security, the system implements JWT-based stateless authentication, RBAC-based fine-grained access control, and TOTP-based two-factor authentication. The system supports four types of approval modes: single-person approval, sequential approval, parallel countersign, and or-sign approval, while providing flexible task transfer mechanisms such as delegation, reassignment, and rollback. In terms of intelligence, the system integrates large language model capabilities to automatically generate approval suggestions, risk warnings, and reference summaries during approval tasks, and supports intelligent form filling through natural language input.

The system has completed functional verification in the development environment, and test results show that the system has achieved the expected design goals in approval process management, dynamic form configuration, and AI-assisted decision-making, effectively improving the efficiency and standardization of enterprise approval management.

**Keywords:** Java language; Flowable workflow engine; Approval system; Spring Boot; LLM intelligent assistance

---

# 目录

1. 引言
   1.1 课题背景
   1.2 国内外研究现状
   1.3 课题意义
2. 开发工具与关键技术概述
   2.1 IntelliJ IDEA 与 VS Code
   2.2 Java 语言
   2.3 Spring Boot 框架
   2.4 Flowable 工作流引擎
   2.5 MariaDB 数据库
   2.6 Vue 框架
   2.7 Spring Security 与 JWT
   2.8 大语言模型技术
3. 系统可行性与需求分析
   3.1 可行性分析
   3.2 需求分析
4. 概要设计
   4.1 功能模块设计
   4.2 数据库设计
5. 详细设计
   5.1 系统架构设计
   5.2 核心功能模块详细设计
6. 系统实现
   6.1 前台功能模块实现
   6.2 后台功能模块实现
7. 结论
8. 参考文献
9. 致谢

---

# 1. 引言

## 1.1 课题背景

近年来，随着信息技术的飞速发展和企业数字化转型战略的深入推进，越来越多的企业开始重视内部管理流程的自动化和智能化建设。审批管理作为企业日常运营中的核心业务环节，涵盖了请假申请、报销审批、采购管理、合同签署等众多场景，直接关系到企业的运营效率、风险管控和决策质量。

传统的审批管理模式主要依赖纸质单据流转和人工传递，存在审批周期长、流转效率低、历史记录难以追溯等突出痛点。随着电子邮件和即时通讯工具的普及，部分企业开始使用邮件审批或聊天工具审批的方式替代纸质流转，然而这种方式虽然在一定程度上提升了流转速度，却仍然缺乏结构化的流程管控能力。审批节点之间的依赖关系不明确、审批权限缺乏细粒度控制、审批数据的统计分析和审计追踪难以实现等问题，使得企业难以对审批流程进行有效的管理和优化。

近年来，工作流引擎技术为解决上述问题提供了有效的技术方案。BPMN 2.0（Business Process Model and Notation）作为业务流程建模的国际标准，已经被广泛应用于企业流程管理系统中。以 Flowable 为代表的开源工作流引擎实现了 BPMN 2.0 标准，提供了流程定义、流程实例管理、任务分配、并行网关等功能，能够支撑复杂的企业审批流转场景。

与此同时，人工智能技术的快速发展为企业管理软件的智能化升级提供了新的可能。以 GPT 系列为代表的大语言模型（Large Language Model, LLM）在自然语言理解、文本生成、数据分析等方面展现出了强大的能力。将大语言模型集成到审批系统中，可以在审批建议生成、风险自动识别、表单智能填充等环节提供辅助决策支持，从而进一步提升审批管理的效率和质量。

基于以上背景，本文设计并实现了一个基于 Flowable 工作流引擎的智能协同审批系统。该系统采用前后端分离的 B/S 架构，后端使用 Spring Boot 框架和 Flowable 工作流引擎实现业务流程的灵活编排与执行，前端使用 Vue 3 框架构建响应式用户界面。系统在传统工作流引擎的基础上，引入了大语言模型智能辅助能力，实现了审批建议自动生成和表单自然语言解析等创新功能，为企业提供了一套完整、灵活、智能的审批管理解决方案。

## 1.2 国内外研究现状

### 1.2.1 工作流技术研究现状

工作流技术的研究可以追溯到二十世纪七十年代的办公自动化研究。1993 年，工作流管理联盟（Workflow Management Coalition, WfMC）成立，制定了工作流参考模型和相关标准，为工作流技术的标准化奠定了基础。此后，工作流技术在企业资源计划（ERP）、办公自动化（OA）等领域得到了广泛应用。

在工作流引擎的实现方面，目前主流的开源解决方案包括 Activiti、Flowable 和 Camunda 等。Activiti 是由 Alfresco 公司于 2010 年发布的开源工作流引擎，其核心开发团队具有丰富的 JBoss jBPM 项目经验。Flowable 由 Activiti 的原始核心团队成员于 2016 年创建，在架构设计上对 Activiti 进行了重大改进，提供了更好的云原生支持和更清晰的服务划分。Camunda 是另一个广受欢迎的 BPMN 工作流引擎，以其高性能和企业级特性著称。在国内，阿里巴巴的 CompileFlow、小米的 Zeus 等自研流程引擎也在企业内部得到了应用。

在学术研究领域，工作流引擎的研究主要集中在流程引擎性能优化、分布式流程调度、柔性工作流、流程挖掘等方面。近年来，随着微服务架构和云原生技术的兴起，工作流引擎的云化部署和容器化运行成为新的研究方向。

### 1.2.2 审批系统研究现状

在审批系统方面，国内外已经涌现出大量成熟的商业产品和开源方案。国际上，ServiceNow、Salesforce 等平台提供了流程自动化能力，涵盖审批管理场景。国内市场上，泛微、致远互联、蓝凌等厂商的 OA 产品在审批管理领域占据重要地位，钉钉和企业微信等平台也内置了基础的审批功能。

然而，当前市场上的审批系统仍存在一些不足。首先，大多数审批系统采用固定流程模板的方式，对于需要灵活调整流程的复杂场景支持不足。其次，审批流程的智能化程度普遍较低，审批人主要依赖个人经验进行决策，缺乏数据驱动的辅助分析能力。第三，多数系统的权限模型较为简单，难以满足大型企业复杂的组织架构和数据权限管理需求。

### 1.2.3 大语言模型在企业管理中的应用

2022 年末 ChatGPT 的发布引发了大语言模型的研究和应用热潮。在企业级应用场景中，大语言模型在智能客服、文档处理、数据分析等领域展现出显著价值。在审批管理领域，已有研究探讨利用大语言模型进行合同审查、风险识别、审批意见生成等任务。然而，将大语言模型深度集成到工作流引擎中，实现审批流程的智能辅助决策，仍是一个具有创新性的研究方向。

综上所述，市场上缺乏将工作流引擎与大语言模型充分结合的审批解决方案。本课题的研究正是针对这一现状，尝试将 Flowable 工作流引擎与大语言模型技术进行有机融合，构建一个兼具流程灵活性和决策智能化的协同审批系统。

## 1.3 课题意义

本课题的研究具有以下方面的意义：

第一，提升审批管理效率。通过工作流引擎实现审批流程的自动化流转，减少人工传递环节，缩短审批周期，提高企业运营效率。系统支持的单人审批、会签、或签、顺序审批等多种审批模式，能够覆盖企业常见的审批场景。

第二，强化审批决策质量。系统集成大语言模型能力，能够在审批环节自动生成审批建议和风险提示，为审批人提供数据驱动的决策参考，降低人为判断失误带来的风险。

第三，增强系统安全性。系统实现了完整的 RBAC 权限模型，支持部门维度的数据权限隔离，并集成 TOTP 双因素认证，确保审批数据的安全性和操作的合规性。

第四，降低企业信息化成本。系统采用 Spring Boot 和 Flowable 等开源技术栈构建，具有良好的可扩展性和可维护性，企业无需支付高额的商业软件许可费用即可获得完整的审批管理能力。

第五，推动智能化办公创新。本课题将大语言模型与工作流引擎的结合方式进行了实践探索，为后续企业管理软件的智能化升级提供了可参考的技术方案和实践经验。

# 2. 开发工具与关键技术概述

## 2.1 IntelliJ IDEA 与 VS Code

### 2.1.1 IntelliJ IDEA

IntelliJ IDEA 是由 JetBrains 公司开发的一款功能强大的 Java 集成开发环境。它提供了智能代码补全、深度代码分析、重构工具以及内置的版本控制系统集成等功能。在本项目的开发过程中，IntelliJ IDEA 被用作后端 Spring Boot 项目的主要开发工具。其强大的 Maven 依赖管理支持和对 Spring Boot 框架的原生集成，极大地提升了后端代码的编写和调试效率。

### 2.1.2 VS Code

Visual Studio Code 是微软公司推出的一款轻量级跨平台代码编辑器。它提供了丰富的插件生态系统，支持 TypeScript、Vue、JavaScript 等多种前端语言的语法高亮和智能感知。在本项目中，VS Code 配合 Volar 插件用于 Vue 3 前端代码的开发，其快速的启动速度和良好的 TypeScript 支持为前端开发提供了高效的体验。

## 2.2 Java 语言

Java 是一种面向对象的编程语言，自 1995 年由 Sun Microsystems 公司发布以来，凭借其"一次编写，到处运行"的跨平台特性和成熟的生态系统，在企业级应用开发领域一直占据主导地位。

Java 语言具有以下突出特点：其一，跨平台特性，Java 程序被编译为与平台无关的字节码，可以在任何安装了 Java 虚拟机（JVM）的平台上运行；其二，面向对象，Java 支持封装、继承和多态等面向对象特性，便于构建结构清晰、可维护的大型应用；其三，内存安全，Java 的自动垃圾回收机制和强类型系统减少了内存泄漏和类型错误等问题；其四，丰富的类库和框架生态，从 Web 开发到大数据处理，Java 拥有最为全面的开源生态支持。

本系统选择 Java 17 版本作为后端开发语言，利用其密封类、模式匹配、Records 等新特性，提升代码的表达力和可读性。

## 2.3 Spring Boot 框架

Spring Boot 是由 Pivotal 团队开发的一个基于 Spring 框架的快速应用开发框架，其核心设计理念是"约定优于配置"。Spring Boot 通过自动配置和起步依赖（Starter），大幅简化了 Spring 应用的搭建和开发过程。

在本系统中，Spring Boot 3.5.10 版本被用作整个后端系统的核心框架。系统通过 spring-boot-starter-web 启动 Web 服务，通过 spring-boot-starter-data-jpa 实现数据持久化，通过 spring-boot-starter-security 集成安全框架，通过 spring-boot-starter-validation 实现请求参数的自动校验。Spring Boot 的自动配置能力使开发者能够将注意力集中在业务逻辑的实现上，而无需花费大量时间进行复杂的基础设施配置。

本系统还充分利用了 Spring 框架的依赖注入（Dependency Injection）和面向切面编程（Aspect-Oriented Programming）特性，通过声明式事务管理（@Transactional）保证了业务操作的数据一致性。

## 2.4 Flowable 工作流引擎

Flowable 是一个基于 Java 语言开发的轻量级开源工作流引擎，完全实现了 BPMN 2.0 标准。Flowable 由原 Activiti 核心团队成员于 2016 年创建，在继承了 Activiti 核心功能的基础上，对引擎架构进行了重构和优化。

Flowable 引擎由多个独立的服务组件构成。流程存储服务（RepositoryService）负责流程定义的存储和版本管理，运行时服务（RuntimeService）负责流程实例的创建和执行，任务服务（TaskService）负责用户任务的管理，历史服务（HistoryService）负责已完成的流程数据和审计记录的查询。

Flowable 支持多种流程节点类型，包括用户任务（UserTask）、服务任务（ServiceTask）、排他网关（ExclusiveGateway）、并行网关（ParallelGateway）等，能够通过 BPMN 2.0 标准定义复杂的业务流转逻辑。在多实例任务方面，Flowable 提供了灵活的循环特性（multiInstanceLoopCharacteristics），支持并行和串行两种多实例执行模式，并支持自定义完成条件（completionCondition），这些特性正是本系统实现会签审批功能的技术基础。

Flowable 还提供了丰富的扩展机制。任务监听器（TaskListener）允许在任务的生命周期事件（如创建、分配、完成）中插入自定义逻辑，执行监听器（ExecutionListener）则可以在流程执行的不同阶段触发自定义行为。本系统利用这些扩展机制实现了审批任务的业务数据记录和状态同步功能。

本系统选择 Flowable 而非其他工作流引擎的原因在于：Flowable 与 Spring Boot 有良好的集成支持，提供了 flowable-spring-boot-starter 起步依赖；其 API 设计清晰，学习曲线适中；社区活跃，文档和参考资料丰富。

## 2.5 MariaDB 数据库

MariaDB 是由 MySQL 原始开发者 Monty Widenius 领导开发的一个开源关系型数据库管理系统，它是 MySQL 的一个分支，保持了与 MySQL 的高度兼容性。MariaDB 在选择存储引擎方面提供了更多灵活性，并且在高并发场景下通常能提供优于 MySQL 的查询性能。

在本系统中，MariaDB 被用作主数据库，存储用户信息、审批流程数据、表单定义和实例数据、操作日志等业务数据。系统通过 Spring Data JPA 框架与数据库进行交互，利用 Hibernate 作为 JPA 的实现提供者，实现了对象关系映射（ORM）。在开发阶段，Hibernate 的 ddl-auto: update 策略被用于根据实体类的变更自动更新数据库表结构，提升了开发迭代效率。在测试环境中，系统使用 H2 内存数据库替代 MariaDB，以实现测试用例的快速执行和环境隔离。

系统设计了包含 22 张数据表的数据库模型，涵盖了 RBAC 权限管理、动态表单、审批业务、工作流管理、系统设置等功能域。各表之间通过外键关联和数据冗余的合理平衡，在保证数据一致性的同时兼顾了查询性能。

## 2.6 Vue 框架

Vue.js 是由尤雨溪于 2014 年发布的一款渐进式 JavaScript 前端框架。Vue 3 是 Vue 框架的最新主版本，于 2020 年正式发布，在性能、TypeScript 支持和组合式 API 方面相比 Vue 2 有了显著提升。

Vue 3 采用基于 Proxy 的响应式系统替代了 Vue 2 中的 Object.defineProperty 方案，解决了此前无法检测属性添加和删除的问题，同时提升了响应式数据的追踪效率。Vue 3 引入了组合式 API（Composition API），通过 setup 函数和响应式引用（ref、reactive），使组件的逻辑组织和复用更加灵活直观，特别适合构建复杂的单页面应用。

在本系统中，前端基于 Vue 3 和 TypeScript 构建，使用 Vite 作为构建工具，Pinia 作为状态管理库，Vue Router 作为路由管理。系统通过 Element Plus 组件库构建用户界面，保证了界面风格的一致性和交互体验的专业性。前端通过 Axios 封装 API 调用层，与后端进行 RESTful 风格的数据交互。

系统前端采用了基于角色的路由访问控制，根据用户角色动态决定导航菜单和可访问页面的范围。普通员工、部门主管、流程设计员和系统管理员四个角色拥有不同的前端界面和功能入口，实现了界面级的权限隔离。

## 2.7 Spring Security 与 JWT

Spring Security 是 Spring 生态系统中用于应用安全防护的核心框架，提供了认证（Authentication）和授权（Authorization）两个层面的完整安全方案。

在认证方面，本系统采用 JWT（JSON Web Token）作为无状态认证方案。用户登录成功后，服务端使用 jjwt 库生成一个包含用户标识、角色列表和过期时间的加密令牌，客户端在后续请求中通过 HTTP 请求头的 Authorization 字段携带该令牌。服务端通过 JwtAuthenticationFilter 过滤器拦截所有请求，解析并验证令牌的有效性，将用户信息加载到 Spring Security 的安全上下文中。这种无状态认证方式避免了服务端 Session 存储的开销，天然适合前后端分离的部署架构。

在授权方面，本系统实现了基于角色的访问控制（Role-Based Access Control, RBAC）。系统定义了普通员工、部门主管、流程设计员、业务管理员和系统管理员五种角色，每种角色拥有不同的系统操作权限。在 URL 级别，通过 SecurityFilterChain 配置了按路径和 HTTP 方法匹配的权限拦截规则。在数据级别，通过 RbacService 实现了基于角色数据范围的部门级数据隔离，确保用户只能查看被授权范围内的审批数据。

在双因素认证方面，系统集成了基于时间的一次性密码（Time-based One-Time Password, TOTP）方案。TOTP 算法基于 HMAC-SHA1 哈希函数，使用共享密钥和当前时间戳生成 6 位动态验证码，有效期通常为 30 秒。用户在登录时通过密码验证后，仍需输入由认证器应用生成的动态验证码，只有两层验证均通过才能获得系统的完整访问权限。系统还支持生成一次性恢复码，用于在用户丢失认证器设备时进行账号恢复。

## 2.8 大语言模型技术

大语言模型（Large Language Model, LLM）是指基于 Transformer 架构、在海量文本数据上训练的大型神经网络模型。以 GPT 系列为代表的大语言模型通过自回归的下一词预测训练方式，学习到了丰富的语言知识和推理能力，能够在自然语言理解、文本生成、代码生成、数据分析等多种任务上展现出接近乃至超越人类的表现。

在本系统中，大语言模型技术应用于两个核心场景。第一，审批建议生成。当审批人打开待办任务时，系统自动收集该任务的上下文信息（包括申请表单数据、申请人历史记录、相似案例统计、系统策略规则等），构造结构化的提示词（Prompt）发送给大语言模型，由模型生成包含审批建议决策、风险警告、异常检测和参考摘要的结构化输出。审批人可以将 AI 建议作为决策参考，并可以通过追问功能对 AI 进行进一步的细节询问。

第二，自然语言表单解析。发起人可以通过自然语言描述申请内容，例如"我申请5月15日到17日去上海出差，预算3000元"。系统将自然语言文本与目标表单的字段定义一起发送给大语言模型或启发式解析器，解析得到结构化的表单数据，自动填充到对应的表单字段中，减少用户的手动输入成本。

系统在 LLM 集成架构上采用了接口抽象的设计模式，定义了统一的 LlmClient 接口，支持 OpenAI 兼容协议的多种模型实现，可在不同模型供应商之间灵活切换。同时系统内置了基于正则表达式和关键词匹配的启发式解析器，作为 LLM 不可用时的降级方案。所有 AI 生成的内容都会被持久化记录在数据库中，并追踪最终的审批结果，用于后续的效果评估和模型优化。

# 3. 系统可行性与需求分析

## 3.1 可行性分析

### (1) 技术可行性分析

本系统所选用的技术栈均为业界成熟的开源技术。Spring Boot 作为 Java 领域最主流的微服务开发框架，拥有庞大的社区和完善的文档支持。Flowable 工作流引擎完全实现了 BPMN 2.0 国际标准，经过多年发展已经具备了企业级的稳定性和可靠性。Vue 3 是前端开发领域广泛使用的响应式框架，配合 Element Plus 组件库可以高效地构建专业的企业级用户界面。

前后端分离的架构设计一方面降低了系统各层之间的耦合度，另一方面使前后端可以独立开发和部署。JWT 无状态认证方案避免了服务端 Session 维护的复杂性。大语言模型的集成采用 HTTP API 调用方式，与系统其他模块解耦，技术实现路径清晰可行。

团队在 Java Web 开发和前端开发方面具备较为扎实的技术基础，开发过程中使用的开发工具和第三方组件均已验证了其在实际项目中的可用性。综合来看，本系统的技术方案成熟可靠，不存在技术实现上的不可逾越障碍。

### (2) 经济可行性分析

本系统采用的 Spring Boot、Flowable、MariaDB、Vue 3 等核心技术和组件均为开源或免费软件，无需支付商业许可费用。系统的开发和运行环境对硬件资源要求不高，一台配置中等的服务器即可满足中小规模企业的日常运行需求。部署方式灵活，支持本地部署和云服务器部署，企业可根据自身情况选择成本最优的方案。

系统提供的自动化审批能力和 AI 辅助决策功能，能够有效减少企业在审批管理上的人力成本投入，降低因审批决策失误造成的经济损失风险，从长期运营角度来看具有良好的经济效益。

### (3) 操作可行性分析

系统采用了基于 Web 浏览器的 B/S 架构，用户无需安装任何客户端软件，通过浏览器即可访问系统的全部功能。前端界面设计遵循通用的企业管理软件交互规范，采用 Element Plus 组件库保证了界面风格的一致性和操作的标准化。系统提供了清晰的角色界面分离，普通用户和管理员分别拥有独立的操作界面和功能入口，降低了不同角色用户的学习成本。

系统的表单填写支持自然语言智能解析，审批环节提供 AI 辅助建议，这些智能化功能显著降低了用户的操作负担。系统的响应式界面设计使其能够在桌面端和平板端均有良好的适配表现。

## 3.2 需求分析

### 3.2.1 用户角色需求

系统需要支持以下四种核心用户角色：

普通员工（EMPLOYEE）是系统的主要用户群体，需要能够发起各类审批申请、查看自己的申请进度和历史记录、在被指定为审批人时处理审批任务，以及管理个人信息和账户安全设置。

部门主管（MANAGER）在具备普通员工全部功能的基础上，需要能够审批下属员工的申请、对审批任务进行委派和转办操作、在审批过程中执行回退操作。

流程设计员（DESIGNER）需要能够创建和管理动态表单定义、设计表单字段和校验规则、管理表单版本。流程设计员还需要能够配置 BPMN 流程定义和管理流程版本。

系统管理员（ADMIN / SYS_ADMIN）需要具备系统的全部管理权限，包括用户管理、角色管理、部门和岗位管理、申请模板管理、系统参数配置，以及用户批量导入和审计日志查看等功能。

### 3.2.2 功能需求

系统需要实现的核心功能需求包含以下几个大类。

在用户认证与安全方面，系统需要支持用户名密码登录、基于 TOTP 的双因素认证、连续登录失败后的账号锁定机制、密码修改功能，以及完整的登录审计日志记录。

在审批流程方面，系统需要支持发起申请、保存和提交草稿、四种审批模式（单人审批、顺序审批、并行会签、或签）、任务认领、任务委派和转办、审批回退（回退到上一步、回退到指定节点、退回发起人）、流程撤销、流程挂起和激活等功能。会签模式需要支持全票通过和多数通过两种策略，多数通过的比例需要可配置。

在动态表单方面，系统需要支持表单的定义和版本化管理，字段类型需要支持字符串、数字、日期、下拉选择和表格等多种类型，字段需要支持必填校验、可见性条件控制和默认值设置。

在 AI 智能辅助方面，系统需要实现审批任务打开时的自动 AI 建议生成，审批人对 AI 建议的追问对话，自然语言描述的表单智能填充，以及 AI 建议的采纳跟踪和效果评估。

在权限管理方面，系统需要支持用户的增删改查、角色的定义和分配、部门树形结构管理、岗位管理、角色数据权限范围的配置，以及用户批量导入功能。

### 3.2.3 非功能需求

在性能方面，高频访问的待办任务查询接口需要保证在正常负载下的响应时间不超过 500 毫秒。系统应支持至少 100 个并发用户的同时使用。

在安全性方面，用户密码必须使用 BCrypt 算法加密存储，JWT Token 需要设置合理的过期时间，敏感的系统配置数据需要支持加密存储，所有审批操作必须记录完整的审计日志。

在可用性方面，前端界面需要适配主流的桌面浏览器（Chrome、Edge、Firefox），系统需要在数据库故障时能够给出明确的错误提示而非静默失败。

在可维护性方面，代码需遵循 Java 和 TypeScript 的标准编码规范，后端需要提供统一的全���异常处理机制，前后端接口需要遵循 RESTful API 设计规范。

# 4. 概要设计

## 4.1 功能模块设计

本系统按功能域划分为以下六个核心模块：

**用户认证与安全管理模块**负责处理用户身份认证和系统安全控制，包含用户登录、JWT Token 管理、TOTP 双因素认证、账号锁定与解锁、密码修改、以及引导模式的系统初始化等功能。该模块是整个系统的安全基石，所有后续操作的入口都依赖此模块提供的认证和授权能力。

**审批流程模块**是系统的核心业务模块，负责审批流程的创建、流转和管理，包含流程发起、草稿管理、任务查询、任务认领、审批执行（通过/拒绝）、任务委派、任务转办、流程回退、流程撤销、流程挂起与激活等功能。该模块通过与 Flowable 工作流引擎的深度集成，实现了 BPMN 2.0 标准下的流程编排和执行。

**动态表单模块**负责审批申请中表单的管理和数据处理，包含表单定义管理、表单版本的创建和发布、字段配置、表单实例的创建和查询、表单数据的流程变量映射、以及附件上传和下载功能。该模块采用版本化管理策略，确保不同时期的审批流程使用对应版本的表单结构。

**AI 智能辅助模块**负责集成大语言模型能力为审批流程提供智能辅助，包含审批建议生成（融合任务上下文、申请人统计、相似案例和风险规则的综合分析）、审批建议追问对话、自然语言表单解析（支持 LLM 解析和启发式正则解析的双轨策略）、AI 聊天助手、以及建议采纳跟踪功能。

**权限管理模块**负责系统用户和组织的管理，包含用户管理、角色管理、部门树管理、岗位管理、用户角色关联、用户岗位关联、角色数据权限范围管理、以及用户批量导入（支持 CSV 文件的预校验和正式导入两阶段操作）功能。

**工作流管理模块**负责流程定义和申请模板的管理和配置，包含流程定义管理、BPMN 版本管理、流程发布和部署、节点配置管理、申请模板管理（含审批规则配置和发起权限控制）、以及发布日志记录功能。

## 4.2 数据库设计

### 4.2.1 E-R 设计

本系统的核心实体关系如下：一个用户（sys_user）可以拥有多个角色（sys_role），用户与角色之间通过 sys_user_role 关联表建立多对多关系。用户属于一个部门（sys_dept），部门之间通过 parent_id 字段形成树形结构。用户可以担任多个岗位（sys_post），通过 sys_user_post 关联表建立多对多关系。

一个审批申请（biz_request）由一名用户发起，关联一个表单实例（form_instance），可以在审批过程中产生多个审批任务记录（biz_request_task）和多条操作日志（biz_request_log）。一个表单定义（form_definition）可以拥有多个版本（form_version），每个表单版本包含多个字段定义（form_field）。一个工作流定义（workflow_definition）同样可以拥有多个版本（workflow_definition_version），每个版本的发布操作被记录在工作流发布日志（workflow_publish_log）中。

系统通过 ai_suggestion_record 表追踪每次 AI 建议的生成和采纳情况，建议关联到具体的审批申请和审批任务。申请模板（request_template）定义了申请流程的预配置规则，绑定表单和工作流定义。

### 4.2.2 数据表设计

系统设计了 22 张数据表，按功能域分为五组。

**RBAC 权限表组**包含 sys_user、sys_role、sys_dept、sys_post、sys_user_role、sys_user_post、sys_role_data_scope、sys_login_log、sys_user_import_job 和 sys_user_import_job_item 共十张表，支撑用户管理、角色授权和组织架构管理功能。

**审批业务表组**包含 biz_request、biz_request_task 和 biz_request_log 三张表。biz_request 表记录每一条审批申请的主数据，包含业务主键、关联的流程实例标识、发起人信息、申请标题、当前状态、当前处理人等核心字段。biz_request_task 表记录每个审批任务的生成和执行情况，包含任务标识、办理人、委派状态、执行动作和审批意见等字段。biz_request_log 表记录审批流程中的每一次操作，形成完整的审批操作审计链路。

**动态表单表组**包含 form_definition、form_version、form_field、form_instance 和 form_attachment 五张表。form_definition 存储表单的基本定义，form_version 实现表单结构的版本化管理，form_field 存储每个版本的字段配置（包括字段类型、校验规则、可见性条件等），form_instance 存储实际填写的表单数据，form_attachment 管理表单附件的元数据。

**工作流管理表组**包含 workflow_definition、workflow_definition_version、workflow_node_config、workflow_publish_log 和 request_template 五张表。workflow_definition 存储流程定义的基本信息，workflow_definition_version 存储每个版本的 BPMN XML 内容和发布状态，workflow_node_config 存储流程中每个节点的审批类型、分配策略和操作权限配置，request_template 存储申请流程的模板规则和发起限制。

**系统设置表组**包含 sys_setting 和 ai_suggestion_record 两张表。sys_setting 采用键值对方式存储系统级配置参数，支持敏感值的加密存储。ai_suggestion_record 存储 AI 建议的生成内容和采纳记录。

# 5. 详细设计

## 5.1 系统架构设计

本系统采用经典的三层架构设计，在整体上呈现为表示层、业务逻辑层和数据访问层的分层结构。

表示层由 Vue 3 前端应用构成，负责用户界面的呈现和交互逻辑的处理。前端通过 Axios 封装的 HTTP 客户端与后端 API 进行通信，所有请求统一携带 JWT Token 进行身份认证。前端路由基于 Vue Router 实现，根据用户角色动态控制页面的访问权限。

业务逻辑层由 Spring Boot 后端应用构成，是整个系统的核心层。控制层（Controller）接收前端请求，完成参数校验和权限检查后，将业务处理委托给服务层（Service）。服务层封装了审批流程管理、表单处理、AI 建议生成、权限管理等核心业务逻辑。Spring Security 过滤器链提供了请求级别的安全拦截，JwtAuthenticationFilter 负责解析和验证每个请求中的 JWT Token。

数据访问层基于 Spring Data JPA 架构，通过 Repository 接口定义数据操作方法。业务表与 Flowable 工作流引擎共用同一个数据源，确保核心审批操作能够在同一个数据库事务中完成，保证业务数据与流程状态的一致性。

在技术组件层面，系统集成了 Flowable 工作流引擎作为流程执行的核心。Flowable 的 RuntimeService 负责流程实例的创建和执行，TaskService 负责用户任务的生命周期管理，HistoryService 提供历史流程数据的查询能力。系统通过与 Flowable 引擎的事务同步机制，在流程操作的同时更新业务状态表，保持业务层与流程引擎层的数据一致性。

在 AI 集成层面，系统定义了统一的 LlmClient 接口抽象层，屏蔽了不同大语言模型提供商之间的差异。OpenAiLlmClient 类实现了与 OpenAI 兼容 API 的对接，可以连接 OpenAI、DeepSeek 及其他兼容的服务商。MockLlmClient 类在 LLM 服务不可用或测试场景下提供模拟的 AI 响应。FormCommandAiService 在 LLM 调用失败时自动回退到基于正则表达式的启发式解析器，保证表单解析功能在各种条件下均可用。

## 5.2 核心功能模块详细设计

### 5.2.1 审批流程发起模块详细设计

审批流程的发起是系统的主要入口功能。用户在前端选择申请模板、填写动态表单后，提交发起请求。后端 WorkflowController 接收到申请后，首先校验发起用户的角色是否具备该模板的发起权限，然后通过 FormService 创建表单数据实例。WorkflowService 调用 RequestTemplateApprovalResolverService 根据模板配置的审批规则自动解析审批人列表，确定审批策略。

审批人自动解析遵循以下优先级：若模板配置了基于直属主管的审批规则，系统查询申请人的 managerUserId 字段获取直属主管；若未配置直属主管，退化为部门负责人（sys_dept 的 leaderUserId）；若仍未获取到，则继续向上级部门查找。对于配置为指定用户的步骤，直接使用模板中预设的用户。解析完成后，系统根据审批人数量自动选择合适的 BPMN 流程：单个审批人使用 approvalSingle 流程，多个审批人使用 approvalSequential 流程。

系统将申请人信息、表单数据、审批人列表、会签模式和通过比例等参数作为流程变量，调用 Flowable 的 RuntimeService 创建流程实例。流程实例创建成功后，系统在同一个事务中向 biz_request、biz_request_task 和 biz_request_log 表写入记录。

### 5.2.2 审批执行模块详细设计

审批任务的执行包含认领、审批、委派、转办和回退五种核心操作。

任务认领是将处于"待认领"状态的任务分配给当前用户的操作。系统调用 Flowable 的 TaskService.claim() 方法将用户设置为任务的办理人（assignee），同时更新 biz_request_task 表中对应记录的状态。

审批通过和审批拒绝是审批执行的核心操作。审批人提交审批结果时，系统首先校验审批意见的必填性和委派状态的有效性。通过 TaskService.complete() 提交任务到 Flowable 引擎后，引擎触发注册的 TaskListener。CountersignTaskListener 在会签场景下负责更新流程变量中的通过计数和拒绝计数，并根据完成条件判断是否达成会签结果。系统在 TaskListener 回调之后刷新业务表状态，将任务记录标记为已完成并写入操作日志。

任务委派允许当前办理人将任务临时委托给他人处理。系统调用 TaskService.delegateTask() 后，原办理人被设置为任务的拥有者（owner），被委派人成为当前办理人（assignee），任务处于委派进行中状态。被委派人处理后，通过 TaskService.resolveTask() 将处理结果返回给原办理人。只有原办理人才能执行最终的完成操作，保证责任追溯的完整性。

任务转办是将任务责任永久转移给他人的操作。系统通过 TaskService.setAssignee() 直接修改任务办理人，任务完成时以新的办理人身份记录审批结果。

审批回退支持三种回退目标：回退到上一个审批节点、回退到指定的 BPMN 节点、退回给发起人重新处理。系统通过 Flowable 的 RuntimeService.createChangeActivityStateBuilder() 实现运行中流程实例的动态跳转，将执行指针移动到目标节点。回退操作会将流程变量（通过计数、拒绝计数等）重置，确保重新审批时流程变量处于正确的初始状态。

### 5.2.3 AI 审批建议模块详细设计

AI 审批建议的生成采用多层数据融合的方式。当审批人请求 AI 建议时，TaskAiSuggestionService 首先从 Flowable 引擎获取任务上下文信息，包括任务名称、申请标题和表单变量。然后从历史数据中统计申请人的月度行为数据（月度申请总数、同类申请数、月度总金额和平均金额）以及相似案例的审批数据（样本数、通过率、拒绝率和平均处理时间）。同时，系统应用预定义的启发式规则检查可能的异常和风险点。

这些数据被组装为结构化的请求对象，通过 LlmClient 接口发送给大语言模型。模型返回的结果经过规范化处理后持久化到数据库。审批人可以查看 AI 的建议决策（建议通过或建议拒绝）、推荐理由、风险警告列表和异常检测结果，并可以通过追问功能对 AI 的某个具体结论进行深入询问。系统还跟踪记录 AI 建议是否被采纳以及申请的最终审批结果，用于评估 AI 建议的准确性和辅助决策效果。

### 5.2.4 动态表单模块详细设计

动态表单的设计采用了版本化策略。表单定义（form_definition）是表单的逻辑标识，每个定义下可以有多个版本（form_version）。每次修改表单结构时，会创建新的版本而非直接修改已有版本，这样已运行的审批流程仍然使用发起时的表单版本，不受后续表单结构变更的影响。

表单版本的状态机包含草稿（DRAFT）、已发布（PUBLISHED）和已归档（ARCHIVED）三个状态。只有处于已发布状态的版本才能被审批流程引用。表单版本发布后进入只读模式，不能再被修改。

字段配置支持六种类型：字符串（string）类型提供文本输入，数字（number）类型提供数值输入并支持最小值最大值的校验，日期（date）和日期时间（datetime）类型提供日期选择器，下拉选择（select）类型提供选项配置和单选功能，表格（table）类型支持结构化的明细数据输入。

表单数据与流程变量的映射通过 variable_key 字段实现。当表单实例被创建时，系统将表单数据映射为流程变量存储到 Flowable 引擎中，使得表单数据可以在 BPMN 网关条件判断和后续审批节点的界面展示中被引用。

### 5.2.5 RBAC 权限管理模块详细设计

系统的权限管理采用基于角色的访问控制模型，结合数据范围过滤实现细粒度的权限管控。权限控制分为两个层次：URL 级别的功能权限和部门级别的数据权限。

在功能权限层面，Spring Security 的 SecurityFilterChain 配置了按 URL 路径和 HTTP 方法匹配的访问规则。例如，/api/admin/** 路径仅允许具有 ADMIN 或 SYS_ADMIN 角色的用户访问，/api/admin/forms/** 路径还额外开放给 DESIGNER 角色。Controller 方法内部通过 SecurityUtils 工具类进行更细粒度的权限判断。

在数据权限层面，RbacService 根据用户角色的数据范围配置（sys_role_data_scope 表）决定用户在查询审批数据时的可见范围。如果角色配置了以部门为维度的数据范围，用户只能查看其授权部门范围内的申请数据。如果角色仅配置为"个人"范围，用户只能查看自己发起的申请。

系统在前端也实现了角色感知的界面控制。Vue Router 的路由守卫在页面跳转时检查用户角色是否满足目标页面的角色要求，不满足时将用户重定向到合适的页面。前端的导航菜单也是根据用户角色动态生成的，不同角色的用户看到的菜单项和功能入口各有不同。

# 6. 系统实现

## 6.1 前台功能模块实现

### 6.1.1 登录与认证页面

登录页面是用户进入系统的入口，提供了用户名和密码输入表单。页面在用户访问时检测系统是否处于首次引导模式（bootstrap 模式），如果是则显示管理员账号创建界面，完成系统初始化后自动跳转到登录页面。若用户启用了双因素认证，登录流程分为两步：第一步提交用户名和密码，验证通过后进入第二步，显示 6 位 TOTP 验证码输入框，验证通过后获得完整的系统访问权限。

登录页面还集成了登录失败次数限制功能。当用户连续多次输入错误的密码后，账号将被临时锁定，系统在前端显示相应的锁定提示信息。

### 6.1.2 用户端主界面

普通用户登录后进入用户端主界面，采用左侧导航菜单加右侧内容区的标准管理后台布局。导航菜单包含"首页"、"发起申请"、"我的待办"、"我的申请"、"我已审批"和"个人中心"六个功能入口。

首页展示用户的待办事项数量、进行中的申请数量、最近的操作动态等汇总信息。发起申请页面提供模板选择和表单填写功能，支持智能表单解析和手动填写两种方式。用户可以在 AI 浮动助手输入框中输入自然语言描述，系统自动解析并填充表单字段，用户可以检查并修改自动填充的结果后再提交。

我的待办页面以列表形式展示当前用户需要处理的审批任务，每条任务显示申请人、申请标题、申请时间和当前任务名称。点击任务行可以展开任务详情，查看申请表单内容、审批历史记录和 AI 审批建议。审批操作区提供通过和拒绝两个主要按钮，支持输入审批意见和查看 AI 辅助分析结果。

我的申请页面以状态标签的形式展示用户发起的所有申请，支持按审批状态（草稿、审批中、已通过、已拒绝、已退回等）进行筛选。用户可以查看每个申请的详细流转记录和当前处理人信息。

### 6.1.3 管理员端主界面

管理员端采用与用户端相同的布局框架，但导航菜单项更为丰富，包含"管理首页"、"表单管理"、"用户管理"、"角色管理"、"申请模板管理"、"部门管理"、"岗位管理"、"工作流管理"和"系统设置"等管理功能入口。

表单管理页面提供了表单定义列表和版本管理功能。管理员可以创建新的表单定义，为表单添加字段配置。字段编辑器支持设置字段类型、标签、是否必填、默认值和选项列表等属性。表单版本管理页面允许管理员查看表单的所有历史版本，进行版本发布和归档操作。

工作流管理页面是管理员进行流程定义和配置的核心界面。页面上方展示流程定义列表，管理员可以为每个流程创建新的 BPMN 版本。版本详情页面集成 BPMN 可视化编辑器，管理员可以在图形化界面中设计和修改流程结构。节点配置面板允许管理员对每个审批节点设置审批类型、分配策略、操作权限（是否允许委派、转办、回退）和 AI 建议开关等参数。流程版本发布后，系统将 BPMN XML 部署到 Flowable 引擎并更新关联信息。

申请模板管理页面提供了模板的创建和维护功能。管理员可以设置模板的审批规则，包括审批步骤的类型（主管审批、部门负责人审批、指定用户审批等）和顺序。模板还可以配置发起权限的角色限制和是否允许发起人手动选择审批人。

## 6.2 后台功能模块实现

### 6.2.1 Spring Boot 应用启动与配置

系统后端是一个标准的 Spring Boot 应用，通过 ApprovalSystemApplication 主类启动。应用启动时，Spring Boot 的自动配置机制根据类路径中的依赖和配置文件中的参数，自动完成 Spring MVC、Spring Data JPA、Spring Security 和 Flowable 引擎的初始化配置。

Spring Data JPA 配置了 Hibernate 的 ddl-auto: update 策略，在开发阶段自动根据实体类的变更更新数据库表结构。Flowable 引擎的 database-schema-update 参数同样设置为 true，由 Flowable 自动创建和维护其内部的功能表。流程定义文件放置在 classpath:/processes/ 目录下，应用启动时 Flowable 自动扫描并部署这些 BPMN 文件。

安全配置（SecurityConfig）设置了无状态的 Session 管理策略，注册了 JwtAuthenticationFilter 作为前置过滤器，定义了基于 URL 路径和角色的访问控制规则。全局异常处理器（GlobalExceptionHandler）统一捕获和处理 Controller 层抛出的异常，将业务异常转换为结构化的错误响应返回给前端。

### 6.2.2 审批流程核心实现

审批流程的核心逻辑集中在 WorkflowService 类中，该类封装了与 Flowable 引擎交互的全部操作。流程发起的核心方法是 startApprovalProcessInternal()，该方法完成以下关键步骤：确定流程定义的 Key、生成或使用指定的业务主键（businessKey）、构建流程变量 Map 并设置业务参数（applicantId、title、formInstanceId 等）、调用审批人解析服务获取审批人和审批策略、根据审批人数量自动选择流程类型、设置会签模式和通过比例变量、调用 Flowable 的 RuntimeService.startProcessInstanceByKey() 或 startProcessInstanceById() 启动流程实例、在同一事务中写入业务表数据。

任务完成操作的实现涉及与 Flowable 引擎的深入交互。completeTask() 方法在调用 TaskService.complete() 之前，完成了多项前置校验：验证审批意见的必填性、检查任务是否处于委派完成等待（Resolved）状态且当前用户是否为原负责人。任务完成提交到 Flowable 引擎后，流程自动流转到下一节点。系统通过 refreshCurrentTask() 方法同步业务状态：查询当前流程实例上的活跃任务，更新 biz_request 表的当前处理人字段；如果流程已结束（活跃任务为空），根据流程变量判断最终结果（通过或拒绝），更新申请状态和结束时间。

### 6.2.3 AI 模块实现

AI 模块的实现分为服务层和接口层两个层次。在服务层，ApprovalSuggestionService 负责构造大语言模型的请求上下文。它将系统收集的任务信息、申请人画像、历史案例统计和政策规则等多个维度的数据组装为结构化的 SuggestionRequest 对象，通过 LlmClient 接口发送给大语言模型。模型返回的 Suggestion 对象经过决策规范化、推荐理由格式化、风险警告列表处理等步骤，转换为对审批人有实际参考价值的建议结果。

FormCommandAiService 实现了自然语言表单的智能解析。当 LLM 服务可用时，系统将用户的自然语言文本和表单字段定义列表发送给模型，由模型解析出结构化的键值对数据。当 LLM 不可用或调用失败时，系统自动回退到启发式解析器。启发式解析器利用正则表达式和关键词匹配技术，针对不同类型字段采用不同的解析策略：数字字段匹配数值模式并排除日期中的数字干扰，金额字段通过货币符号和金额关键词定位，日期字段支持 ISO 8601 标准格式和中文日期格式（如"2026年5月15日"），选择字段通过在命令文本中搜索选项标签来匹配，字符串字段通过字段别名（标签和字段键）从命令文本中提取对应值。此外，启发式解析器还能识别中文数字表达（如"三天"、"七人"）和通过日期区间自动计算天数时长。

TaskAiSuggestionService 作为 AI 建议的缓存和持久化层，负责将每次 AI 建议的生成结果持久化到 ai_suggestion_record 表。它跟踪建议的采纳状态和最终审批结果，为后续的效果分析提供数据基础。

### 6.2.4 安全模块实现

JWT Service 提供了两种令牌的生成和校验功能。Access Token 是用户登录成功后获得的正式访问令牌，有效期为 120 分钟，载荷中包含用户 ID、用户名和角色列表。Challenge Token 是开启双因素认证的用户在密码验证通过后获得的临时挑战令牌，有效期仅 5 分钟，仅用于二步验证环节。两种令牌在载荷中通过 type 字段进行区分，防止令牌类型的混用。

JwtAuthenticationFilter 是请求认证的入口过滤器。它在每个请求到达 Controller 之前拦截执行，从 HTTP 请求头的 Authorization 字段提取 JWT 令牌，调用 JwtService.parseAccessToken() 解析和验证令牌的有效性。验证通过后，从令牌的 Claims 中提取用户 ID、用户名和角色信息，构造 AuthUserPrincipal 和 UsernamePasswordAuthenticationToken 对象，将其设置到 Spring Security 的 SecurityContextHolder 中，后续的 Controller 和 Service 层即可通过 SecurityUtils 工具类获取当前登录用户的信息。

TOTP 双因素认证基于标准的 TOTP 算法（RFC 6238）实现。用户首次设置双因素认证时，系统生成一个随机密钥，该密钥以 Base32 编码后与系统标识一起生成 otpauth URI。前端用户使用认证器应用扫描生成的二维码完成绑定。登录时的验证过程使用 HMAC-SHA1 算法结合密钥和当前时间窗口生成期望的验证码，与用户输入的验证码进行比对。系统还支持生成一组一次性恢复码，以加密形式存储在用户记录中，用于用户在丢失认证器设备时的应急登录。

# 7. 结论

本文围绕企业审批管理的实际需求，设计并实现了一个基于 Flowable 工作流引擎的智能协同审批系统。系统采用前后端分离的 B/S 架构，后端基于 Spring Boot 3.5 框架集成 Flowable 7.0 工作流引擎，前端使用 Vue 3 和 TypeScript 构建响应式用户界面，在代码实现层面达到了约 4 万行的规模。

系统实现的主要成果包括以下几个方面：第一，基于 BPMN 2.0 标准的工作流引擎集成，支持单人审批、顺序审批、并行会签和或签四种审批模式，以及任务委派、转办、回退等灵活的操作机制，能够满足企业多样化的审批场景需求。第二，版本化的动态表单系统，支持多种字段类型和灵活的表单配置，表单版本与流程版本绑定，保证了历史数据的完整性。第三，基于 RBAC 的细粒度权限管控，结合部门级数据权限隔离和双因素认证机制，建立了完善的安全防护体系。第四，大语言模型的创新集成，在审批建议生成和表单自然语言解析两个场景实现了 AI 辅助决策，提升了系统的智能化水平。

系统在开发阶段完成了 30 余个集成测试类的编写和执行，覆盖了审批流程、表单管理、用户管理和 AI 功能等核心业务场景，验证了系统功能的正确性和稳定性。

本系统仍存在一些可以进一步优化的方向。在流程可视化方面，增强 BPMN 设计器的功能，支持更复杂的条件表达式编辑和流程仿真预览。在 AI 集成方面，可以利用更多的历史审批数据对大语言模型的建议进行持续优化，提升建议的准确率和采纳率。在性能方面，可以对高频查询接口引入缓存机制，对大字段数据实施读写分离。在部署方面，可以引入 Docker 容器化部署方案，提升系统的部署便捷性和环境一致性。

总体而言，本系统通过将工作流引擎与大语言模型技术相结合，在传统审批管理系统的基础上实现了智能化升级，达到了预期的设计目标。系统的完成和测试结果验证了技术方案的可行性，为企业审批管理的数字化转型提供了一个有参考价值的技术方案。

# 8. 参考文献

[1] 刘俊强. 基于 Activiti 的工作流引擎在 OA 系统中的应用研究[D]. 西安电子科技大学, 2018.

[2] 杨浩淼, 李铎. 基于 Spring Boot 的轻量级微服务框架设计与实现[J]. 计算机技术与发展, 2022, 32(3): 35-42.

[3] 冯志勇, 李文杰, 李晓红. 工作流管理技术综述[J]. 计算机集成制造系统, 2020, 26(4): 889-901.

[4] Object Management Group. Business Process Model and Notation (BPMN) Version 2.0[S]. OMG Document Number: formal/2011-01-03, 2011.

[5] Flowable Project Team. Flowable Documentation[EB/OL]. https://www.flowable.com/open-source/docs/, 2026.

[6] 尤雨溪. Vue.js 设计与实现[M]. 人民邮电出版社, 2022.

[7] Spring Team. Spring Boot Reference Documentation[EB/OL]. https://docs.spring.io/spring-boot/docs/current/reference/htmlsingle/, 2026.

[8] Craig Walls. Spring Boot in Action[M]. Manning Publications, 2016.

[9] Brown T B, Mann B, Ryder N, et al. Language Models are Few-Shot Learners[C]. Advances in Neural Information Processing Systems, 2020, 33: 1877-1901.

[10] 吴翰清. 白帽子讲 Web 安全[M]. 电子工业出版社, 2012.

[11] Hardt D. The OAuth 2.0 Authorization Framework[S]. RFC 6749, Internet Engineering Task Force, 2012.

[12] M'Raihi D, Machani S, Pei M, et al. TOTP: Time-Based One-Time Password Algorithm[S]. RFC 6238, Internet Engineering Task Force, 2011.

[13] 李智慧. 大型网站技术架构: 核心原理与案例分析[M]. 电子工业出版社, 2013.

[14] Jones M, Bradley J, Sakimura N. JSON Web Token (JWT)[S]. RFC 7519, Internet Engineering Task Force, 2015.

[15] Gamma E, Helm R, Johnson R, et al. Design Patterns: Elements of Reusable Object-Oriented Software[M]. Addison-Wesley, 1995.

# 9. 致谢

在本论文完成之际，谨向在课题研究和论文撰写过程中给予我帮助和支持的各位老师、同学和家人致以最诚挚的谢意。

首先要衷心感谢我的指导教师[导师姓名]老师。在课题选题、技术方案设计、系统开发和论文撰写的各个阶段，老师都给予了我悉心的指导和宝贵的建议。每当遇到技术难点和论文写作困惑时，老师的耐心指导和专业见解总能为我指明前进的方向。老师严谨的治学态度和扎实的专业素养对我的学习和成长影响深远。

感谢所有授课老师，大学期间所学的专业知识和技能为本课题的研究和开发工作奠定了坚实的基础。

感谢实验室的各位同学，在系统开发过程中大家互相帮助、共同探讨技术问题，营造了良好的学习和研究氛围。

最后要感谢我的家人，你们的默默支持和无私付出是我能够专注于学业并顺利完成毕业论文的坚实后盾。

