CREATE OR REPLACE FORCE VIEW XXCFO_PO_DEPT_V(
/*************************************************************************
 * 
 * View Name       : XXCFO_PO_DEPT_V
 * Description     : 発注者部門ビュー
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.1
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2008/12/16    1.0  SCS 山口 優   初回作成
 *  2009/02/06    1.1  SCS 嵐田勇人  [障害CFO_001]事業所アドオンマスタの有効日付チェックを追加
 ************************************************************************/
  location_code,                -- 事業所コード
  location_short_name           -- 略称
) AS
  SELECT hl.location_code               location_code            -- 事業所コード
        ,xla.location_short_name        location_short_name      -- 略称
    FROM hr_locations               hl           -- 事業所マスタ
        ,xxcmn_locations_all        xla          -- 事業所アドオンマスタ
        ,per_all_people_f           papf         -- 従業員マスタ
        ,po_agents                  pa           -- 購買担当マスタ
  WHERE hl.location_id       = xla.location_id              -- 事業所マスタ.事業所ID = 事業所アドオンマスタ.事業所ID
    AND TRUNC(SYSDATE) BETWEEN TRUNC(xla.start_date_active)             -- TRUNC(SYSDATE) BETWEEN TRUNC(事業所アドオンマスタ.適用開始日)
                           AND TRUNC(NVL(xla.end_date_active, SYSDATE)) --                    AND TRUNC(NVL(事業所アドオンマスタ.適用終了日,SYSDATE))
    AND pa.agent_id          = papf.person_id               -- 購買担当マスタ.購買担当ID = 従業員マスタ.従業員ID
    AND papf.attribute28     = hl.location_code             -- 従業員マスタ.DFF28 = 事業所マスタ.事業所コード
    AND TRUNC(SYSDATE) BETWEEN TRUNC(pa.start_date_active)             -- TRUNC(SYSDATE) BETWEEN TRUNC(購買担当マスタ.適用開始日)
                           AND TRUNC(NVL(pa.end_date_active, SYSDATE)) --                    AND TRUNC(NVL(購買担当マスタ.適用終了日,SYSDATE))
    AND TRUNC(SYSDATE) BETWEEN TRUNC(papf.effective_start_date)             -- TRUNC(SYSDATE) BETWEEN TRUNC(従業員マスタ.有効開始日)
                           AND TRUNC(NVL(papf.effective_end_date, SYSDATE)) --                    AND TRUNC(NVL(従業員マスタ.有効終了日,SYSDATE))
    AND papf.current_employee_flag = 'Y'         -- 従業員マスタ.現在従業員フラグ = 'Y'
  GROUP BY hl.location_code                      -- 事業所コード
          ,xla.location_short_name               -- 略称
/
