CREATE OR REPLACE FORCE VIEW XXCFR_COMPANY_LOV_V(
/*************************************************************************
 * 
 * View Name       : XXCFR_COMPANY_LOV_V
 * Description     : 会社LOVビュー
 * MD.050          : 
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------   -------------------------------------
 *  Date          Ver.  Editor         Description
 * ------------- ----- ------------   -------------------------------------
 *  2023/10/24    1.0  SCSK 大山       初回作成
 ************************************************************************/
  company_code,          -- 会社コード
  company_name           -- 会社名
) AS
  -- ログインユーザの所属部門、(標準)請求書全社出力権限有無
  WITH login_user AS ( 
    SELECT papf.attribute28  AS dept_code  -- 所属部門コード
          ,(CASE
              WHEN flvv.attribute3 = 'Y' THEN
                'Y'
              ELSE
                'N'
            END)             AS all_flag   -- (標準)請求書全社出力権限有無
    FROM   fnd_user             fu
          ,per_all_people_f     papf
          ,fnd_lookup_values_vl flvv
    WHERE  fu.user_id           = fnd_global.user_id  -- ログインユーザID
    AND    fu.employee_id       = papf.person_id
    AND    SYSDATE BETWEEN papf.effective_start_date AND papf.effective_end_date
    AND    papf.attribute28     = flvv.lookup_code(+)
    AND    flvv.lookup_type(+)  = 'XXCFR1_INVOICE_ALL_OUTPUT_DEPT'
    AND    flvv.enabled_flag(+) = 'Y'
  )
  -- (標準)請求書全社出力権限あり
  SELECT xcv.company_code  AS company_code   -- 会社コード
        ,xcv.company_name  AS company_name   -- 会社名
  FROM   xxcfo_company_v xcv
        ,login_user      lu
  WHERE  lu.all_flag = 'Y'
  --
  UNION ALL
  -- (標準)請求書全社出力権限なし
  SELECT xcv.company_code  AS company_code   -- 会社コード
        ,xcv.company_name  AS company_name   -- 会社名
  FROM   xxcfo_company_v xcv
        ,login_user      lu
  WHERE  lu.all_flag = 'N'
  AND    EXISTS (
           -- ログインユーザの所属部門の会社に絞り込み
           SELECT 1
           FROM   xx03_departments_ext_v  xdev
           WHERE  xdev.set_of_books_id         = FND_PROFILE.VALUE('GL_SET_OF_BKS_ID')
           AND    xdev.enabled_flag            = 'Y'
           AND    xdev.flex_value              = lu.dept_code
           AND    NVL(xdev.attribute10, '001') = xcv.company_code
         )
/
COMMENT ON COLUMN  xxcfr_company_lov_v.company_code          IS '会社コード'
/
COMMENT ON COLUMN  xxcfr_company_lov_v.company_name          IS '会社名'
/
