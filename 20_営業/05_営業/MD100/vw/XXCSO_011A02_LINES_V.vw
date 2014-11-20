/*************************************************************************
 * 
 * VIEW Name       : XXCSO_011A02_LINES_V
 * Description     : CSO_011_A02_作業依頼／発注依頼検索画面明細ビュー
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2009/12/22    1.0  T.Maruyama    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW apps.xxcso_011a02_lines_v
(
seq_no,
slip_no,
slip_branch_no,
line_number,
job_kbn,
install_code1,
install_code2,
work_hope_date,
work_hope_time_kbn,
work_hope_time,
current_install_name,
new_install_name,
withdrawal_process_kbn,
actual_work_date,
actual_work_time1,
actual_work_time2,
completion_kbn,
delete_flag,
completion_plan_date,
completion_date,
disposal_approval_date,
withdrawal_date,
delivery_date,
last_disposal_end_date,
fwd_root_company_code,
fwd_root_location_code,
fwd_distination_company_code,
fwd_distination_location_code,
creation_employee_number,
creation_section_name,
creation_program_id,
update_employee_number,
update_section_name,
update_program_id,
creation_date_time,
update_date_time,
po_number,
po_line_number,
po_distribution_number,
po_req_number,
line_num,
account_number1,
account_number2,
safe_setting_standard,
install1_processed_flag,
install2_processed_flag,
suspend_processed_flag,
install1_processed_date,
install2_processed_date,
vdms_interface_flag,
vdms_interface_date,
install1_process_no_target_flg,
install2_process_no_target_flg,
created_by,
creation_date,
last_updated_by,
last_update_date,
last_update_login,
request_id,
program_application_id,
program_id,
program_update_date,
infos_interface_flag,
infos_interface_date,
completion_kbn_nm
)
AS
SELECT
seq_no                              -- シーケンス番号
,slip_no                            -- 伝票No.
,slip_branch_no                     -- 伝票枝番
,line_number                        -- 行番号
,job_kbn                            -- 作業区分
,install_code1                      -- 物件コード１（設置用）
,install_code2                      -- 物件コード２（引揚用）
,work_hope_date                     -- 作業希望日/引取希望日
,work_hope_time_kbn                 -- 作業希望時間区分
,work_hope_time                     -- 作業希望時間
,current_install_name               -- 現設置先名
,new_install_name                   -- 新設置先名
,withdrawal_process_kbn             -- 引揚機処理区分
,actual_work_date                   -- 実作業日
,actual_work_time1                  -- 実作業時間１
,actual_work_time2                  -- 実作業時間２
,completion_kbn                     -- 完了区分
,delete_flag                        -- 削除フラグ
,completion_plan_date               -- 完了予定日/修理完了予定日
,completion_date                    -- 完了日/修理完了日
,disposal_approval_date             -- 廃棄決裁日
,withdrawal_date                    -- 実引取日/引取日
,delivery_date                      -- 交付日
,last_disposal_end_date             -- 最終処分終了年月日
,fwd_root_company_code              -- （転送元）会社コード
,fwd_root_location_code             -- （転送元）事業所コード
,fwd_distination_company_code       -- （転送先）会社コード
,fwd_distination_location_code      -- （転送先）事業所コード
,creation_employee_number           -- 作成担当者コード
,creation_section_name              -- 作成部署コード
,creation_program_id                -- 作成プログラムＩＤ
,update_employee_number             -- 更新担当者コード
,update_section_name                -- 更新部署コード
,update_program_id                  -- 更新プログラムＩＤ
,creation_date_time                 -- 作成日時時分秒
,update_date_time                   -- 更新日時時分秒
,po_number                          -- 発注番号
,po_line_number                     -- 発注明細番号
,po_distribution_number             -- 発注搬送番号
,po_req_number                      -- 発注依頼番号
,line_num                           -- 発注依頼明細番号
,account_number1                    -- 顧客コード１（新設置先）
,account_number2                    -- 顧客コード２（現設置先）
,safe_setting_standard              -- 安全設置基準
,install1_processed_flag            -- 物件１処理済フラグ
,install2_processed_flag            -- 物件２処理済フラグ
,suspend_processed_flag             -- 休止処理済フラグ
,install1_processed_date            -- 物件１処理済日
,install2_processed_date            -- 物件２処理済日
,vdms_interface_flag                -- 自販機S連携フラグ
,vdms_interface_date                -- 自販機S連携日
,DECODE(install_code1
        ,NULL
        ,NULL
        ,install1_process_no_target_flg
       )install1_process_no_target_flg       -- 物件１作業依頼処理対象外フラグ
,DECODE(install_code2
        ,NULL
        ,NULL
        ,install2_process_no_target_flg
       )install2_process_no_target_flg     -- 物件２作業依頼処理対象外フラグ
,created_by                         -- 作成者
,creation_date                      -- 作成日
,last_updated_by                    -- 最終更新者
,last_update_date                   -- 最終更新日
,last_update_login                  -- 最終更新ログイン
,request_id                         -- 要求ID
,program_application_id             -- コンカレント・プログラム・アプリケーションID
,program_id                         -- コンカレント・プログラムID
,program_update_date                -- プログラム更新日
,infos_interface_flag               -- 情報系連携済フラグ
,infos_interface_date               -- 情報系連携日
,DECODE(completion_kbn
       ,1,'完了','中止') completion_kbn_nm   -- 作業区分内容
FROM  xxcso_in_work_data   xiwd     -- 作業データ
WITH READ ONLY
;

COMMENT ON TABLE XXCSO_011A02_LINES_V IS 'CSO_011_A02_明細ビュー';