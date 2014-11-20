/*************************************************************************
 * 
 * VIEW Name       : xxcso_visit_actual_v
 * Description     : 共通用：有効訪問実績ビュー
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/04/14    1.0  K.Satomura    初回作成
 *  2009/04/24    1.1  K.Satomura    システムテスト障害対応(T1_0734)
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_visit_actual_v
(
   task_id
  ,created_by
  ,creation_date
  ,last_updated_by
  ,last_update_date
  ,last_update_login
  ,object_version_number
  ,task_number
  ,task_type_id
  ,task_status_id
  ,task_priority_id
  ,owner_id
  ,owner_type_code
  ,owner_territory_id
  ,assigned_by_id
  ,cust_account_id
  ,customer_id
  ,address_id
  ,planned_start_date
  ,planned_end_date
  ,scheduled_start_date
  ,scheduled_end_date
  ,actual_start_date
  ,actual_end_date
  ,source_object_type_code
  ,timezone_id
  ,source_object_id
  ,source_object_name
  ,duration
  ,duration_uom
  ,planned_effort
  ,planned_effort_uom
  ,actual_effort
  ,actual_effort_uom
  ,percentage_complete
  ,reason_code
  ,private_flag
  ,publish_flag
  ,restrict_closure_flag
  ,multi_booked_flag
  ,milestone_flag
  ,holiday_flag
  ,billable_flag
  ,bound_mode_code
  ,soft_bound_flag
  ,workflow_process_id
  ,notification_flag
  ,notification_period
  ,notification_period_uom
  ,parent_task_id
  ,recurrence_rule_id
  ,alarm_start
  ,alarm_start_uom
  ,alarm_on
  ,alarm_count
  ,alarm_fired_count
  ,alarm_interval
  ,alarm_interval_uom
  ,deleted_flag
  ,palm_flag
  ,wince_flag
  ,laptop_flag
  ,device1_flag
  ,device2_flag
  ,device3_flag
  ,costs
  ,currency_code
  ,org_id
  ,escalation_level
  ,attribute1
  ,attribute2
  ,attribute3
  ,attribute4
  ,attribute5
  ,attribute6
  ,attribute7
  ,attribute8
  ,attribute9
  ,attribute10
  ,attribute11
  ,attribute12
  ,attribute13
  ,attribute14
  ,attribute15
  ,attribute_category
  ,security_group_id
  ,orig_system_reference
  ,orig_system_reference_id
  ,update_status_flag
  ,calendar_start_date
  ,calendar_end_date
  ,date_selected
  ,template_id
  ,template_group_id
  ,object_changed_date
  ,task_confirmation_status
  ,task_confirmation_counter
  ,task_split_flag
  ,open_flag
  ,entity
  ,child_position
  ,child_sequence_num
  ,party_id
)
AS
SELECT jtb.task_id
      ,jtb.created_by
      ,jtb.creation_date
      ,jtb.last_updated_by
      ,jtb.last_update_date
      ,jtb.last_update_login
      ,jtb.object_version_number
      ,jtb.task_number
      ,jtb.task_type_id
      ,jtb.task_status_id
      ,jtb.task_priority_id
      ,jtb.owner_id
      ,jtb.owner_type_code
      ,jtb.owner_territory_id
      ,jtb.assigned_by_id
      ,jtb.cust_account_id
      ,jtb.customer_id
      ,jtb.address_id
      ,jtb.planned_start_date
      ,jtb.planned_end_date
      ,jtb.scheduled_start_date
      ,jtb.scheduled_end_date
      ,jtb.actual_start_date
      ,jtb.actual_end_date
      ,jtb.source_object_type_code
      ,jtb.timezone_id
      ,jtb.source_object_id
      ,jtb.source_object_name
      ,jtb.duration
      ,jtb.duration_uom
      ,jtb.planned_effort
      ,jtb.planned_effort_uom
      ,jtb.actual_effort
      ,jtb.actual_effort_uom
      ,jtb.percentage_complete
      ,jtb.reason_code
      ,jtb.private_flag
      ,jtb.publish_flag
      ,jtb.restrict_closure_flag
      ,jtb.multi_booked_flag
      ,jtb.milestone_flag
      ,jtb.holiday_flag
      ,jtb.billable_flag
      ,jtb.bound_mode_code
      ,jtb.soft_bound_flag
      ,jtb.workflow_process_id
      ,jtb.notification_flag
      ,jtb.notification_period
      ,jtb.notification_period_uom
      ,jtb.parent_task_id
      ,jtb.recurrence_rule_id
      ,jtb.alarm_start
      ,jtb.alarm_start_uom
      ,jtb.alarm_on
      ,jtb.alarm_count
      ,jtb.alarm_fired_count
      ,jtb.alarm_interval
      ,jtb.alarm_interval_uom
      ,jtb.deleted_flag
      ,jtb.palm_flag
      ,jtb.wince_flag
      ,jtb.laptop_flag
      ,jtb.device1_flag
      ,jtb.device2_flag
      ,jtb.device3_flag
      ,jtb.costs
      ,jtb.currency_code
      ,jtb.org_id
      ,jtb.escalation_level
      ,jtb.attribute1
      ,jtb.attribute2
      ,jtb.attribute3
      ,jtb.attribute4
      ,jtb.attribute5
      ,jtb.attribute6
      ,jtb.attribute7
      ,jtb.attribute8
      ,jtb.attribute9
      ,jtb.attribute10
      ,jtb.attribute11
      ,jtb.attribute12
      ,jtb.attribute13
      ,jtb.attribute14
      ,jtb.attribute15
      ,jtb.attribute_category
      ,jtb.security_group_id
      ,jtb.orig_system_reference
      ,jtb.orig_system_reference_id
      ,jtb.update_status_flag
      ,jtb.calendar_start_date
      ,jtb.calendar_end_date
      ,jtb.date_selected
      ,jtb.template_id
      ,jtb.template_group_id
      ,jtb.object_changed_date
      ,jtb.task_confirmation_status
      ,jtb.task_confirmation_counter
      ,jtb.task_split_flag
      ,jtb.open_flag
      ,jtb.entity
      ,jtb.child_position
      ,jtb.child_sequence_num
      ,jtb.source_object_id
FROM   jtf_tasks_b jtb
WHERE  jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
AND    jtb.source_object_type_code = 'PARTY'
AND    jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
AND    NVL(jtb.deleted_flag, 'N')  = 'N'
AND    jtb.actual_end_date IS NOT NULL
UNION ALL
SELECT jtb.task_id
      ,jtb.created_by
      ,jtb.creation_date
      ,jtb.last_updated_by
      ,jtb.last_update_date
      ,jtb.last_update_login
      ,jtb.object_version_number
      ,jtb.task_number
      ,jtb.task_type_id
      ,jtb.task_status_id
      ,jtb.task_priority_id
      ,jtb.owner_id
      ,jtb.owner_type_code
      ,jtb.owner_territory_id
      ,jtb.assigned_by_id
      ,jtb.cust_account_id
      ,jtb.customer_id
      ,jtb.address_id
      ,jtb.planned_start_date
      ,jtb.planned_end_date
      ,jtb.scheduled_start_date
      ,jtb.scheduled_end_date
      ,jtb.actual_start_date
      ,jtb.actual_end_date
      ,jtb.source_object_type_code
      ,jtb.timezone_id
      ,jtb.source_object_id
      ,jtb.source_object_name
      ,jtb.duration
      ,jtb.duration_uom
      ,jtb.planned_effort
      ,jtb.planned_effort_uom
      ,jtb.actual_effort
      ,jtb.actual_effort_uom
      ,jtb.percentage_complete
      ,jtb.reason_code
      ,jtb.private_flag
      ,jtb.publish_flag
      ,jtb.restrict_closure_flag
      ,jtb.multi_booked_flag
      ,jtb.milestone_flag
      ,jtb.holiday_flag
      ,jtb.billable_flag
      ,jtb.bound_mode_code
      ,jtb.soft_bound_flag
      ,jtb.workflow_process_id
      ,jtb.notification_flag
      ,jtb.notification_period
      ,jtb.notification_period_uom
      ,jtb.parent_task_id
      ,jtb.recurrence_rule_id
      ,jtb.alarm_start
      ,jtb.alarm_start_uom
      ,jtb.alarm_on
      ,jtb.alarm_count
      ,jtb.alarm_fired_count
      ,jtb.alarm_interval
      ,jtb.alarm_interval_uom
      ,jtb.deleted_flag
      ,jtb.palm_flag
      ,jtb.wince_flag
      ,jtb.laptop_flag
      ,jtb.device1_flag
      ,jtb.device2_flag
      ,jtb.device3_flag
      ,jtb.costs
      ,jtb.currency_code
      ,jtb.org_id
      ,jtb.escalation_level
      ,jtb.attribute1
      ,jtb.attribute2
      ,jtb.attribute3
      ,jtb.attribute4
      ,jtb.attribute5
      ,jtb.attribute6
      ,jtb.attribute7
      ,jtb.attribute8
      ,jtb.attribute9
      ,jtb.attribute10
      ,jtb.attribute11
      ,jtb.attribute12
      ,jtb.attribute13
      ,jtb.attribute14
      ,jtb.attribute15
      ,jtb.attribute_category
      ,jtb.security_group_id
      ,jtb.orig_system_reference
      ,jtb.orig_system_reference_id
      ,jtb.update_status_flag
      ,jtb.calendar_start_date
      ,jtb.calendar_end_date
      ,jtb.date_selected
      ,jtb.template_id
      ,jtb.template_group_id
      ,jtb.object_changed_date
      ,jtb.task_confirmation_status
      ,jtb.task_confirmation_counter
      ,jtb.task_split_flag
      ,jtb.open_flag
      ,jtb.entity
      ,jtb.child_position
      ,jtb.child_sequence_num
      ,ala.customer_id
FROM   jtf_tasks_b  jtb
      ,as_leads_all ala
WHERE  jtb.task_status_id          = fnd_profile.value('XXCSO1_TASK_STATUS_CLOSED_ID')
AND    jtb.source_object_type_code = 'OPPORTUNITY'
AND    jtb.task_type_id            = fnd_profile.value('XXCSO1_TASK_TYPE_VISIT')
AND    NVL(jtb.deleted_flag, 'N')  = 'N'
AND    jtb.actual_end_date IS NOT NULL
/* 2009.04.24 K.Satomura T1_0734対応 START */
--AND    ala.customer_id             = jtb.source_object_id
AND    ala.lead_id                 = jtb.source_object_id
/* 2009.04.24 K.Satomura T1_0734対応 END */
WITH READ ONLY
;
COMMENT ON COLUMN xxcso_visit_actual_v.task_id IS 'タスクID';
COMMENT ON COLUMN xxcso_visit_actual_v.created_by IS '作成者';
COMMENT ON COLUMN xxcso_visit_actual_v.creation_date IS '作成日';
COMMENT ON COLUMN xxcso_visit_actual_v.last_updated_by IS '最終更新者';
COMMENT ON COLUMN xxcso_visit_actual_v.last_update_date IS '最終更新日';
COMMENT ON COLUMN xxcso_visit_actual_v.last_update_login IS '最終更新ログイン';
COMMENT ON COLUMN xxcso_visit_actual_v.object_version_number IS 'オブジェクトバージョン番号';
COMMENT ON COLUMN xxcso_visit_actual_v.task_number IS 'タスク番号';
COMMENT ON COLUMN xxcso_visit_actual_v.task_type_id IS 'タスクタイプID';
COMMENT ON COLUMN xxcso_visit_actual_v.task_status_id IS 'タスクステータスID';
COMMENT ON COLUMN xxcso_visit_actual_v.task_priority_id IS 'タスク優先ID';
COMMENT ON COLUMN xxcso_visit_actual_v.owner_id IS '所有者ID';
COMMENT ON COLUMN xxcso_visit_actual_v.owner_type_code IS '所有者タイプコード';
COMMENT ON COLUMN xxcso_visit_actual_v.owner_territory_id IS '所有者区域ID';
COMMENT ON COLUMN xxcso_visit_actual_v.assigned_by_id IS '割当者ID';
COMMENT ON COLUMN xxcso_visit_actual_v.cust_account_id IS 'アカウントID';
COMMENT ON COLUMN xxcso_visit_actual_v.customer_id IS '顧客ID';
COMMENT ON COLUMN xxcso_visit_actual_v.address_id IS 'アドレスID';
COMMENT ON COLUMN xxcso_visit_actual_v.planned_start_date IS '計画開始日';
COMMENT ON COLUMN xxcso_visit_actual_v.planned_end_date IS '計画終了日';
COMMENT ON COLUMN xxcso_visit_actual_v.scheduled_start_date IS '予定開始日';
COMMENT ON COLUMN xxcso_visit_actual_v.scheduled_end_date IS '予定終了日';
COMMENT ON COLUMN xxcso_visit_actual_v.actual_start_date IS '実績開始日';
COMMENT ON COLUMN xxcso_visit_actual_v.actual_end_date IS '実績終了日';
COMMENT ON COLUMN xxcso_visit_actual_v.source_object_type_code IS 'ソースオブジェクトタイプコード';
COMMENT ON COLUMN xxcso_visit_actual_v.timezone_id IS '時差ID';
COMMENT ON COLUMN xxcso_visit_actual_v.source_object_id IS 'ソースオブジェクトID';
COMMENT ON COLUMN xxcso_visit_actual_v.source_object_name IS 'ソースオブジェクト名';
COMMENT ON COLUMN xxcso_visit_actual_v.duration IS '持続';
COMMENT ON COLUMN xxcso_visit_actual_v.duration_uom IS '持続単位';
COMMENT ON COLUMN xxcso_visit_actual_v.planned_effort IS '活動計画';
COMMENT ON COLUMN xxcso_visit_actual_v.planned_effort_uom IS '活動計画単位';
COMMENT ON COLUMN xxcso_visit_actual_v.actual_effort IS '活動実績';
COMMENT ON COLUMN xxcso_visit_actual_v.actual_effort_uom IS '活動実績単位';
COMMENT ON COLUMN xxcso_visit_actual_v.percentage_complete IS '進捗率';
COMMENT ON COLUMN xxcso_visit_actual_v.reason_code IS '理由コード';
COMMENT ON COLUMN xxcso_visit_actual_v.private_flag IS 'プライベートフラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.publish_flag IS '発行フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.restrict_closure_flag IS '閉鎖制限フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.multi_booked_flag IS 'マルチ予約フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.milestone_flag IS 'マイルストーンフラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.holiday_flag IS '休日フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.billable_flag IS '請求可能フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.bound_mode_code IS 'バウンドモードコード';
COMMENT ON COLUMN xxcso_visit_actual_v.soft_bound_flag IS 'ソフトバウンドフラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.workflow_process_id IS 'ワークフロープロセスID';
COMMENT ON COLUMN xxcso_visit_actual_v.notification_flag IS '通知フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.notification_period IS '通知期間';
COMMENT ON COLUMN xxcso_visit_actual_v.notification_period_uom IS '通知期間単位';
COMMENT ON COLUMN xxcso_visit_actual_v.parent_task_id IS '親タスクID';
COMMENT ON COLUMN xxcso_visit_actual_v.recurrence_rule_id IS '再発規則ID';
COMMENT ON COLUMN xxcso_visit_actual_v.alarm_start IS '警告開始';
COMMENT ON COLUMN xxcso_visit_actual_v.alarm_start_uom IS '警告開始単位';
COMMENT ON COLUMN xxcso_visit_actual_v.alarm_on IS '警告中';
COMMENT ON COLUMN xxcso_visit_actual_v.alarm_count IS '警告カウント';
COMMENT ON COLUMN xxcso_visit_actual_v.alarm_fired_count IS '解雇警告カウント';
COMMENT ON COLUMN xxcso_visit_actual_v.alarm_interval IS '警告間隔';
COMMENT ON COLUMN xxcso_visit_actual_v.alarm_interval_uom IS '警告間隔単位';
COMMENT ON COLUMN xxcso_visit_actual_v.deleted_flag IS '削除済フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.palm_flag IS '扁平フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.wince_flag IS 'ウィンスフラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.laptop_flag IS 'ラップトップフラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.device1_flag IS 'デバイス１';
COMMENT ON COLUMN xxcso_visit_actual_v.device2_flag IS 'デバイス２';
COMMENT ON COLUMN xxcso_visit_actual_v.device3_flag IS 'デバイス３';
COMMENT ON COLUMN xxcso_visit_actual_v.costs IS '経費';
COMMENT ON COLUMN xxcso_visit_actual_v.currency_code IS '通貨コード';
COMMENT ON COLUMN xxcso_visit_actual_v.org_id IS '組織ID';
COMMENT ON COLUMN xxcso_visit_actual_v.escalation_level IS 'エスカレーションレベル';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute1 IS '訪問区分１';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute2 IS '訪問区分２';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute3 IS '訪問区分３';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute4 IS '訪問区分４';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute5 IS '訪問区分５';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute6 IS '訪問区分６';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute7 IS '訪問区分７';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute8 IS '訪問区分８';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute9 IS '訪問区分９';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute10 IS '訪問区分１０';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute11 IS '有効訪問区分';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute12 IS '登録元区分';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute13 IS '登録元ソース番号';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute14 IS '顧客ステータス';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute15 IS '';
COMMENT ON COLUMN xxcso_visit_actual_v.attribute_category IS '属性分類';
COMMENT ON COLUMN xxcso_visit_actual_v.security_group_id IS 'セキュリティグループID';
COMMENT ON COLUMN xxcso_visit_actual_v.orig_system_reference IS 'オリジナルシステムリファレンス';
COMMENT ON COLUMN xxcso_visit_actual_v.orig_system_reference_id IS 'オリジナルシステムリファレンスID';
COMMENT ON COLUMN xxcso_visit_actual_v.update_status_flag IS 'ステータス更新フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.calendar_start_date IS 'カレンダー開始日';
COMMENT ON COLUMN xxcso_visit_actual_v.calendar_end_date IS 'カレンダー終了日';
COMMENT ON COLUMN xxcso_visit_actual_v.date_selected IS '選択日';
COMMENT ON COLUMN xxcso_visit_actual_v.template_id IS 'テンプレートID';
COMMENT ON COLUMN xxcso_visit_actual_v.template_group_id IS 'テンプレートグループID';
COMMENT ON COLUMN xxcso_visit_actual_v.object_changed_date IS 'オブジェクト変更日';
COMMENT ON COLUMN xxcso_visit_actual_v.task_confirmation_status IS 'タスク確認開始';
COMMENT ON COLUMN xxcso_visit_actual_v.task_confirmation_counter IS 'タスク確認カウンター';
COMMENT ON COLUMN xxcso_visit_actual_v.task_split_flag IS 'タスク分割フラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.open_flag IS 'オープンフラグ';
COMMENT ON COLUMN xxcso_visit_actual_v.entity IS '実体';
COMMENT ON COLUMN xxcso_visit_actual_v.child_position IS '子ポジション';
COMMENT ON COLUMN xxcso_visit_actual_v.child_sequence_num IS '子シーケンス番号';
COMMENT ON COLUMN xxcso_visit_actual_v.party_id IS 'パーティーID';

COMMENT ON TABLE xxcso_visit_actual_v IS '共通用：有効訪問実績ビュー';
