CREATE OR REPLACE VIEW APPS.XXCFF_LEASED_OBJECT_V
AS 
SELECT xoh.object_header_id              AS object_header_id           -- 物件内部ＩＤ
     , xoh.object_code                   AS object_code                -- 物件コード
     , xoh.lease_class                   AS lease_class_code           -- リース種別コード
     ,(SELECT xlcv.lease_class_name
       FROM   xxcff_lease_class_v          xlcv
       WHERE  xoh.lease_class = xlcv.lease_class_code) AS lease_class_name           -- リース種別名称
     , xoh.department_code               AS department_code            -- 管理部門コード
     ,(SELECT xdv.department_name
       FROM   xxcff_department_v           xdv
       WHERE  xoh.department_code = xdv.department_code) AS department_name           -- 管理部門名称
     , xoh.object_status                AS object_status_code         -- 物件ステータスコード
     ,(SELECT xosv.object_status_name
       FROM   xxcff_object_status_v        xosv
       WHERE  xoh.object_status = xosv.object_status_code) AS object_status_name           -- 物件ステータス名称
     , xoh.manufacturer_name             AS manufacturer_name          -- メーカー名
     , xoh.age_type                      AS age_type                   -- 年式
     , xoh.model                         AS model                      -- 機種
     , xoh.serial_number                 AS serial_number              -- 機番
     , xoh.chassis_number                AS chassis_number             -- 車台番号
     , xctmp.lease_company_code          AS lease_company_code         -- リース会社コード
     , xctmp.lease_company_name          AS lease_company_name         -- リース会社名称
     , xctmp.contract_number             AS contract_number            -- 契約番号
     , xctmp.contract_line_id            AS contract_line_id           -- 契約明細内部ID
     , xctmp.contract_line_num           AS contract_line_num          -- 枝番
     , xctmp.lease_kind_code             AS lease_kind_code            -- リース種類コード
     , xctmp.lease_kind_name             AS lease_kind_name            -- リース種類名称
     , xoh.lease_type                    AS lease_type_code            -- リース区分コード
     ,(SELECT xltv.lease_type_name
       FROM   xxcff_lease_type_v           xltv
       WHERE  xoh.lease_type = xltv.lease_type_code) AS lease_type_name           -- リース区分名称
     , xctmp.contract_status_code        AS contract_status_code       -- 契約ステータスコード
     , xctmp.contract_status_name        AS contract_status_name       -- 契約ステータス名称
     , xoh.re_lease_times                AS re_lease_times             -- 再リース回数
     , xoh.re_lease_flag                 AS re_lease_flag_code         -- 再リース要フラグコード
     ,(SELECT xrlfv.re_lease_flag_name
       FROM   xxcff_re_lease_flag_v        xrlfv
       WHERE  xoh.re_lease_flag = xrlfv.re_lease_flag_code) AS re_lease_flag_name           -- 再リース要フラグ名称
     , xctmp.contract_date               AS contract_date              -- リース契約日
     , xctmp.lease_start_date            AS lease_start_date           -- リース開始日
     , xctmp.lease_end_date              AS lease_end_date             -- リース終了日
     , xoh.cancellation_date             AS cancellation_date          -- 中途解約日
     , xoh.bond_acceptance_flag          AS bond_acceptance_flag_code  -- 証書受領フラグコード
     ,(SELECT xbafv.bond_acceptance_flag_name
       FROM   xxcff_bond_acceptance_flag_v xbafv
       WHERE  xoh.bond_acceptance_flag = xbafv.bond_acceptance_flag_code) AS bond_acceptance_flag_name           -- 証書受領フラグ名称
     , xoh.expiration_date               AS expiration_date            -- 満了日
     , xoh.owner_company                AS owner_company_code         -- 本社工場コード
     ,(SELECT xocv.owner_company_name
       FROM   xxcff_owner_company_v        xocv
       WHERE  xoh.owner_company = xocv.owner_company_code) AS owner_company_name           -- 本社工場名称
     , xoh.active_flag                     AS active_flag_code           -- 有効フラグコード
     ,(SELECT xafv.active_flag_name
       FROM   xxcff_active_flag_v          xafv
       WHERE  xoh.active_flag = xafv.active_flag_code) AS active_flag_name           -- 有効フラグ
     , xctmp.estimated_cash_price        AS estimated_cash_price       -- 購入価額
     , xctmp.second_total_charge         AS second_total_charge        -- 月額リース料
     , xctmp.second_total_deduction      AS second_total_deduction     -- 月額控除額
     , xctmp.gross_total_charge          AS gross_total_charge         -- リース料総額
     , xoh.created_by                    AS created_by                 -- 作成者
     , xoh.creation_date                 AS creation_date              -- 作成日
     , xoh.last_updated_by               AS last_updated_by            -- 最終更新者
     , xoh.last_update_date              AS last_update_date           -- 最終更新日
     , xoh.last_update_login             AS last_update_login          -- 最終更新ログイン
FROM   xxcff_object_headers         xoh
     , (SELECT  temp.contract_number        AS contract_number         -- 契約番号
              , temp.contract_date          AS contract_date           -- リース契約日
              , temp.lease_start_date       AS lease_start_date        -- リース開始日
              , temp.lease_end_date         AS lease_end_date          -- リース終了日
              , temp.contract_line_id       AS contract_line_id        -- 契約明細内部ID
              , temp.contract_line_num      AS contract_line_num       -- 明細番号
              , temp.object_header_id       AS object_header_id        -- 物件内部ID
              , temp.expiration_date        AS expiration_date         -- 満了日
              , temp.estimated_cash_price   AS estimated_cash_price    -- 見積現金購入価額
              , temp.second_total_charge    AS second_total_charge     -- 2回目以降計_リース料
              , temp.second_total_deduction AS second_total_deduction  -- 2回目以降計_控除額
              , temp.gross_total_charge     AS gross_total_charge      -- 総額計_リース料
              , temp.lease_company          AS lease_company_code      -- リース会社コード
              ,(SELECT xlcv.lease_company_name
                FROM   xxcff_lease_company_v    xlcv
                WHERE  temp.lease_company = xlcv.lease_company_code) AS lease_company_name      -- リース会社名
              , temp.lease_kind               AS lease_kind_code         -- リース種類コード
              ,(SELECT xlkv.lease_kind_name
                FROM   xxcff_lease_kind_v       xlkv
                WHERE  temp.lease_kind = xlkv.lease_kind_code) AS lease_kind_name         -- リース種類名
              , temp.contract_status   AS contract_status_code    -- 契約ステータスコード
              ,(SELECT xcsv.contract_status_name
                FROM   xxcff_contract_status_v  xcsv
                WHERE  temp.contract_status = xcsv.contract_status_code) AS contract_status_name    -- 契約ステータス名
        FROM   (SELECT  RANK() OVER( partition BY xcl.object_header_id
                                     ORDER     BY xch.re_lease_times DESC
                               )                     AS ranking  -- 物件内部ID単位で再リース回数の降順に採番
                       , xch.contract_number         AS contract_number         -- 契約番号
                       , xch.contract_date           AS contract_date           -- リース契約日
                       , xch.lease_start_date        AS lease_start_date        -- リース開始日
                       , xch.lease_end_date          AS lease_end_date          -- リース終了日
                       , xcl.contract_line_id        AS contract_line_id        -- 契約明細内部ID
                       , xcl.contract_line_num       AS contract_line_num       -- 明細番号
                       , xcl.second_total_charge     AS second_total_charge     -- 2回目以降計_リース料
                       , xcl.second_total_deduction  AS second_total_deduction  -- 2回目以降計_控除額
                       , xcl.gross_total_charge      AS gross_total_charge      -- 総額計_リース料
                       , xcl.estimated_cash_price    AS estimated_cash_price    -- 見積現金購入価額
                       , xcl.object_header_id        AS object_header_id        -- 物件内部ID
                       , xcl.expiration_date         AS expiration_date         -- 満了日
                       , xch.lease_company           AS lease_company           -- リース会社
                       , xcl.lease_kind              AS lease_kind              -- リース種類
                       , xcl.contract_status         AS contract_status         -- 契約ステータス
                 FROM    xxcff_contract_headers  xch   -- リース契約
                       , xxcff_contract_lines    xcl   -- リース契約明細
                 WHERE   xch.contract_header_id = xcl.contract_header_id  -- 契約内部ID
                )                        temp  -- 契約
        WHERE   temp.ranking         = 1    -- 最新の契約明細
       )                            xctmp  -- 契約関連
WHERE  xoh.object_header_id     = xctmp.object_header_id(+)  -- 物件内部ID

