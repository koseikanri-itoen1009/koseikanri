CREATE OR REPLACE PACKAGE BODY APPS.XXCCP003A05C
AS
/*****************************************************************************************
 * Copyright(c)SCSK Corporation, 2020. All rights reserved.
 *
 * Package Name     : XXCCP003A05C(body)
 * Description      : 不正控除支払検知
 * MD.070           : 不正控除支払検知(MD070_IPO_CCP_003_A05)
 * Version          : 1.4
 *
 * Program List
 * ---------------------- ----------------------------------------------------------
 *  Name                   Description
 * ---------------------- ----------------------------------------------------------
 *  submain                メイン処理プロシージャ
 *  main                   コンカレント実行ファイル登録プロシージャ
 *
 * Change Record
 * ------------- ----- ---------------- -------------------------------------------------
 *  Date          Ver.  Editor           Description
 * ------------- ----- ---------------- -------------------------------------------------
 *  2022/03/15    1.0   K.Yoshikawa     [E_本稼動_18075]新規作成
 *  2022/06/08    1.1   K.Yoshikawa     [E_本稼動_18306]
 *  2022/08/02    1.2   SCSK Y.Koh      [E_本稼動_18517]
 *  2023/05/25    1.3   K.Yoshikawa     [E_本稼動_19244]
 *  2023/06/14    1.4   K.Yoshikawa     [E_本稼動_19244]
 *
 *****************************************************************************************/
--
--#######################  固定グローバル定数宣言部 START   #######################
--
  --ステータス・コード
  cv_status_normal CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_normal; --正常:0
  cv_status_warn   CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_warn;   --警告:1
  cv_status_error  CONSTANT VARCHAR2(1) := xxccp_common_pkg.set_status_error;  --異常:2
--
  cv_msg_part      CONSTANT VARCHAR2(3) := ' : ';
  cv_msg_cont      CONSTANT VARCHAR2(3) := '.';
--
--################################  固定部 END   ##################################
--
--#######################  固定グローバル変数宣言部 START   #######################
--
  gv_out_msg       VARCHAR2(2000);
  gn_target_cnt    NUMBER;                    -- 対象件数
  gn_normal_cnt    NUMBER;                    -- 正常件数
  gn_error_cnt     NUMBER;                    -- エラー件数
  gn_warn_cnt      NUMBER;                    -- 警告件数
--
--################################  固定部 END   ##################################
--
--##########################  固定共通例外宣言部 START  ###########################
--
  --*** 処理部共通例外 ***
  global_process_expt       EXCEPTION;
  --*** 共通関数例外 ***
  global_api_expt           EXCEPTION;
  --*** 共通関数OTHERS例外 ***
  global_api_others_expt    EXCEPTION;
--
  PRAGMA EXCEPTION_INIT(global_api_others_expt,-20000);
--
--################################  固定部 END   ##################################
--
  -- ===============================
  -- ユーザー定義例外
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル定数
  -- ===============================
  cv_pkg_name        CONSTANT VARCHAR2(100)   := 'XXCCP003A05C'; -- パッケージ名
  cv_appl_short_name CONSTANT VARCHAR2(10)    := 'XXCCP';        -- アドオン：共通・IF領域
--
  -- ===============================
  -- ユーザー定義グローバル型
  -- ===============================
--
  -- ===============================
  -- ユーザー定義グローバル変数
  -- ===============================
--
  /**********************************************************************************
   * Procedure Name   : submain
   * Description      : メイン処理プロシージャ
   **********************************************************************************/
  PROCEDURE submain(
    iv_process_date       IN  VARCHAR2      --   業務日付
   ,ov_errbuf             OUT VARCHAR2      --   エラー・メッセージ           --# 固定 #
   ,ov_retcode            OUT VARCHAR2      --   リターン・コード             --# 固定 #
   ,ov_errmsg             OUT VARCHAR2      --   ユーザー・エラー・メッセージ --# 固定 #
  )
  IS
--
--#####################  固定ローカル定数変数宣言部 START   ####################
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name             CONSTANT VARCHAR2(100) := 'submain';           -- プログラム名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf  VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode VARCHAR2(1);     -- リターン・コード
    lv_errmsg  VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
--
--###########################  固定部 END   ####################################
--
    -- ===============================
    -- ユーザー宣言部
    -- ===============================
    -- *** ローカル定数 ***
--
    -- *** ローカル変数 ***
    ld_date    DATE;
--
    -- ===============================
    -- ローカル・カーソル
    -- ===============================
    -- ● 控除消込明細情報（AP申請）
    CURSOR main_cur1
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --支払請求拠点       
           h.recon_slip_num        recon_slip_num         , --支払伝票番号       
           h.recon_status          recon_status           , --消込ステータス     
           h.applicant             applicant              , --申請者             
           h.application_date      application_date       , --申請日             
           h.approver              approver               , --承認者             
           h.approval_date         approval_date          , --承認日             
           h.payee_code            payee_code             , --支払先             
           h.invoice_date          invoice_date           , --請求書日付         
           h.recon_due_date        recon_due_date         , --支払予定日         
           h.interface_div         interface_div          , --連携先             
           h.gl_date               gl_date                , --GL記帳日           
           h.corp_code             corp_code              , --条件_企業          
           h.deduction_chain_code  deduction_chain_code_c , --条件_控除用チェーン
           h.cust_code             cust_code              , --条件_顧客          
           h.condition_no          condition_no           , --条件_控除番号      
           h.target_data_type      target_data_type       , --条件_対象データ種類
           h.target_date_end       target_date_end        , --条件_対象期間TO    
           h.invoice_number        invoice_number         , --条件_受領請求書番号
           l.deduction_chain_code  deduction_chain_code   , --控除用チェーン     
           l.deduction_amt         deduction_amt          , --控除額_本体額      
           l.payment_amt           payment_amt            , --支払額_本体額      
           l.difference_amt        difference_amt         , --調整差額_本体額    
           l.deduction_tax         deduction_tax          , --控除額_税額        
           l.payment_tax           payment_tax            , --支払額_税額        
           l.difference_tax        difference_tax           --調整差額_税額      
       FROM
           xxcok.xxcok_deduction_recon_line_ap l,
           xxcok.xxcok_deduction_recon_head    h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- メインカーソルレコード型
    main_rec1  main_cur1%ROWTYPE;
--
    -- ● 控除No別消込情報
    CURSOR main_cur2
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --支払請求拠点        
           h.recon_slip_num        recon_slip_num         , --支払伝票番号        
           h.recon_status          recon_status           , --消込ステータス      
           h.applicant             applicant              , --申請者              
           h.application_date      application_date       , --申請日              
           h.approver              approver               , --承認者              
           h.approval_date         approval_date          , --承認日              
           h.payee_code            payee_code             , --支払先              
           h.invoice_date          invoice_date           , --請求書日付          
           h.recon_due_date        recon_due_date         , --支払予定日          
           h.interface_div         interface_div          , --連携先              
           h.gl_date               gl_date                , --GL記帳日            
           h.corp_code             corp_code              , --条件_企業           
           h.deduction_chain_code  deduction_chain_code_c , --条件_控除用チェーン 
           h.cust_code             cust_code              , --条件_顧客           
           h.condition_no          condition_no_c         , --条件_控除番号       
           h.target_data_type      target_data_type       , --条件_対象データ種類 
           h.target_date_end       target_date_end        , --条件_対象期間TO     
           h.invoice_number        invoice_number         , --条件_受領請求書番号 
           l.deduction_chain_code  deduction_chain_code   , --控除用チェーン      
           l.condition_no          condition_no           , --控除番号            
           l.data_type             data_type              , --データ種類          
           l.payment_tax_code      payment_tax_code       , --支払時税コード      
           l.deduction_amt         deduction_amt          , --控除額_本体額       
           l.payment_amt           payment_amt            , --支払額_本体額       
           l.difference_amt        difference_amt         , --調整差額_本体額     
           l.deduction_tax         deduction_tax          , --控除額_税額         
           l.payment_tax           payment_tax            , --支払額_税額         
           l.difference_tax        difference_tax           --調整差額_税額       
       FROM
           xxcok.xxcok_deduction_num_recon   l,
           xxcok.xxcok_deduction_recon_head  h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- メインカーソルレコード型
    main_rec2  main_cur2%ROWTYPE;
--
    -- ● 控除消込明細情報（問屋未収）
    CURSOR main_cur3
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --支払請求拠点        
           h.recon_slip_num        recon_slip_num         , --支払伝票番号        
           h.recon_status          recon_status           , --消込ステータス      
           h.applicant             applicant              , --申請者              
           h.application_date      application_date       , --申請日              
           h.approver              approver               , --承認者              
           h.approval_date         approval_date          , --承認日              
           h.payee_code            payee_code             , --支払先              
           h.invoice_date          invoice_date           , --請求書日付          
           h.recon_due_date        recon_due_date         , --支払予定日          
           h.interface_div         interface_div          , --連携先              
           h.gl_date               gl_date                , --GL記帳日            
           h.corp_code             corp_code              , --条件_企業           
           h.deduction_chain_code  deduction_chain_code_c , --条件_控除用チェーン 
           h.cust_code             cust_code              , --条件_顧客           
           h.condition_no          condition_no           , --条件_控除番号       
           h.target_data_type      target_data_type       , --条件_対象データ種類 
           h.target_date_end       target_date_end        , --条件_対象期間TO     
           h.invoice_number        invoice_number         , --条件_受領請求書番号 
           l.deduction_chain_code  deduction_chain_code   , --控除用チェーン      
           l.deduction_amt         deduction_amt          , --控除額_本体額       
           l.payment_amt           payment_amt            , --支払額_本体額       
           l.difference_amt        difference_amt         , --調整差額_本体額     
           l.deduction_tax         deduction_tax          , --控除額_税額         
           l.payment_tax           payment_tax            , --支払額_税額         
           l.difference_tax        difference_tax           --調整差額_税額       
       FROM
           xxcok.xxcok_deduction_recon_line_wp l,
           xxcok.xxcok_deduction_recon_head    h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- メインカーソルレコード型
    main_rec3  main_cur3%ROWTYPE;
--
    -- ● 商品別突合情報
    CURSOR main_cur4
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --支払請求拠点        
           h.recon_slip_num        recon_slip_num         , --支払伝票番号        
           h.recon_status          recon_status           , --消込ステータス      
           h.applicant             applicant              , --申請者              
           h.application_date      application_date       , --申請日              
           h.approver              approver               , --承認者              
           h.approval_date         approval_date          , --承認日              
           h.payee_code            payee_code             , --支払先              
           h.invoice_date          invoice_date           , --請求書日付          
           h.recon_due_date        recon_due_date         , --支払予定日          
           h.interface_div         interface_div          , --連携先              
           h.gl_date               gl_date                , --GL記帳日            
           h.corp_code             corp_code              , --条件_企業           
           h.deduction_chain_code  deduction_chain_code_c , --条件_控除用チェーン 
           h.cust_code             cust_code              , --条件_顧客           
           h.condition_no          condition_no           , --条件_控除番号       
           h.target_data_type      target_data_type       , --条件_対象データ種類 
           h.target_date_end       target_date_end        , --条件_対象期間TO     
           h.invoice_number        invoice_number         , --条件_受領請求書番号 
           l.deduction_chain_code  deduction_chain_code   , --控除用チェーン      
           l.item_code             item_code              , --品目                
           l.tax_code              tax_code               , --消費税コード        
           l.deduction_amt         deduction_amt          , --控除額_本体額       
           l.payment_amt           payment_amt            , --支払額_本体額       
           l.difference_amt        difference_amt         , --調整差額_本体額     
           l.deduction_tax         deduction_tax          , --控除額_税額         
           l.payment_tax           payment_tax            , --支払額_税額         
           l.difference_tax        difference_tax           --調整差額_税額       
       FROM
           xxcok.xxcok_deduction_item_recon  l,
           xxcok.xxcok_deduction_recon_head  h
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND ( l.deduction_amt - l.payment_amt !=  l.difference_amt  OR  l.deduction_tax - l.payment_tax !=  l.difference_tax  );
    -- メインカーソルレコード型
    main_rec4  main_cur4%ROWTYPE;
--
    -- ● 控除No別消込情報(積み上げ不正)
    CURSOR main_cur5
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --支払請求拠点        
           h.recon_slip_num        recon_slip_num         , --支払伝票番号        
           h.recon_status          recon_status           , --消込ステータス      
           h.applicant             applicant              , --申請者              
           h.application_date      application_date       , --申請日              
           h.approver              approver               , --承認者              
           h.approval_date         approval_date          , --承認日              
           h.payee_code            payee_code             , --支払先              
           h.invoice_date          invoice_date           , --請求書日付          
           h.recon_due_date        recon_due_date         , --支払予定日          
           h.interface_div         interface_div          , --連携先              
           h.gl_date               gl_date                , --GL記帳日            
           h.corp_code             corp_code              , --条件_企業           
           h.deduction_chain_code  deduction_chain_code_c , --条件_控除用チェーン 
           h.cust_code             cust_code              , --条件_顧客           
           h.condition_no          condition_no           , --条件_控除番号       
           h.target_data_type      target_data_type       , --条件_対象データ種類 
           h.target_date_end       target_date_end        , --条件_対象期間TO     
           h.invoice_number        invoice_number         , --条件_受領請求書番号 
--2022/06/08 1.1 add start
           l.deduction_chain_code  deduction_chain_code   ,
--2022/06/08 1.1 add end
           l.deduction_amt         deduction_amt          ,
           l.deduction_tax         deduction_tax          ,
           l.payment_amt           payment_amt            ,
           l.payment_tax           payment_tax            ,
           l.difference_amt        difference_amt         ,
           l.difference_tax        difference_tax         ,
           SUM(n.payment_amt)      sum_payment_amt        ,
           SUM(n.payment_tax)      sum_payment_tax
       FROM
           xxcok.xxcok_deduction_num_recon     n,
           xxcok.xxcok_deduction_recon_head    h,
           xxcok.xxcok_deduction_recon_line_ap l
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND n.recon_slip_num                =   l.recon_slip_num
       AND nvl(n.deduction_chain_code,'-') = nvl(l.deduction_chain_code,'-')
       GROUP BY
           h.recon_base_code      ,
           h.recon_slip_num       ,
           h.recon_status         ,
           h.applicant            ,
           h.application_date     ,
           h.approver             ,
           h.approval_date        ,
           h.payee_code           ,
           h.invoice_date         ,
           h.recon_due_date       ,
           h.interface_div        ,
           h.gl_date              ,
           h.corp_code            ,
           h.deduction_chain_code ,
           h.cust_code            ,
           h.condition_no         ,
           h.target_data_type     ,
           h.target_date_end      ,
           h.invoice_number       ,
--2022/06/08 1.1 add start
           l.deduction_chain_code ,
--2022/06/08 1.1 add end
           l.deduction_amt        ,
           l.deduction_tax        ,
           l.payment_amt          ,
           l.payment_tax          ,
           l.difference_amt       ,
           l.difference_tax       
       HAVING
           l.payment_amt !=  sum(n.payment_amt)  OR  l.payment_tax !=  sum(n.payment_tax);
    -- メインカーソルレコード型
    main_rec5  main_cur5%ROWTYPE;
--
    -- ● 商品別消込情報(積み上げ不正)
    CURSOR main_cur6
    IS
       SELECT
           h.recon_base_code       recon_base_code        , --支払請求拠点        
           h.recon_slip_num        recon_slip_num         , --支払伝票番号        
           h.recon_status          recon_status           , --消込ステータス      
           h.applicant             applicant              , --申請者              
           h.application_date      application_date       , --申請日              
           h.approver              approver               , --承認者              
           h.approval_date         approval_date          , --承認日              
           h.payee_code            payee_code             , --支払先              
           h.invoice_date          invoice_date           , --請求書日付          
           h.recon_due_date        recon_due_date         , --支払予定日          
           h.interface_div         interface_div          , --連携先              
           h.gl_date               gl_date                , --GL記帳日            
           h.corp_code             corp_code              , --条件_企業           
           h.deduction_chain_code  deduction_chain_code_c , --条件_控除用チェーン 
           h.cust_code             cust_code              , --条件_顧客           
           h.condition_no          condition_no           , --条件_控除番号       
           h.target_data_type      target_data_type       , --条件_対象データ種類 
           h.target_date_end       target_date_end        , --条件_対象期間TO     
           h.invoice_number        invoice_number         , --条件_受領請求書番号 
--2022/06/08 1.1 add start
           l.deduction_chain_code  deduction_chain_code   ,
--2022/06/08 1.1 add end
           l.deduction_amt         deduction_amt ,
           l.deduction_tax         deduction_tax ,
           l.payment_amt           payment_amt   ,
           l.payment_tax           payment_tax   ,
           l.difference_amt        difference_amt,
           l.difference_tax        difference_tax,
           sum(n.payment_amt)      sum_payment_amt,
           sum(n.payment_tax)      sum_payment_tax
       FROM
           xxcok.xxcok_deduction_item_recon    n,
           xxcok.xxcok_deduction_recon_head    h,
           xxcok.xxcok_deduction_recon_line_wp l
       WHERE
           h.recon_status                  NOT IN ('CD','DD')
       AND l.recon_slip_num                =   h.recon_slip_num
       AND l.last_update_date              >=  ld_date
       AND n.recon_slip_num                =   l.recon_slip_num
       AND n.deduction_chain_code          =   l.deduction_chain_code
       GROUP BY
           h.recon_base_code      ,
           h.recon_slip_num       ,
           h.recon_status         ,
           h.applicant            ,
           h.application_date     ,
           h.approver             ,
           h.approval_date        ,
           h.payee_code           ,
           h.invoice_date         ,
           h.recon_due_date       ,
           h.interface_div        ,
           h.gl_date              ,
           h.corp_code            ,
           h.deduction_chain_code ,
           h.cust_code            ,
           h.condition_no         ,
           h.target_data_type     ,
           h.target_date_end      ,
           h.invoice_number       ,
--2022/06/08 1.1 add start
           l.deduction_chain_code ,
--2022/06/08 1.1 add end
           l.deduction_amt        ,
           l.deduction_tax        ,
           l.payment_amt          ,
           l.payment_tax          ,
           l.difference_amt       ,
           l.difference_tax       
       HAVING
           l.payment_amt !=  sum(n.payment_amt)  OR  l.payment_tax !=  sum(n.payment_tax);
    -- メインカーソルレコード型
    main_rec6  main_cur6%ROWTYPE;
--
--2022/06/08 1.1 add start
    -- ● 販売控除情報と控除No別、商品別の金額不一致検知
    CURSOR main_cur7
    IS
       SELECT
         h.creation_date                                                                                                        creation_date           ,--作成日
         h.deduction_recon_head_id                                                                                              deduction_recon_head_id ,--控除消込ヘッダーID
         h.recon_slip_num                                                                                                       recon_slip_num          ,--支払伝票番号
         h.applicant                                                                                                            applicant               ,--申請者
         (SELECT nvl(description,h.applicant) FROM fnd_user fu WHERE fu.user_name = h.applicant)                                applicant_name          ,--申請者
         h.approver                                                                                                             approver                ,--承認者
         (SELECT nvl(description,h.approver) FROM fnd_user fu WHERE fu.user_name = h.approver)                                  approver_name           ,--承認者
         h.recon_due_date                                                                                                       recon_due_date          ,--支払予定日
         h.recon_base_code                                                                                                      recon_base_code         ,--支払請求拠点
         h.payee_code                                                                                                           payee_code              ,--支払先コード
         h.recon_status                                                                                                         recon_status_code       ,--消込ステータスコード
         decode(h.recon_status,'EG','入力中','SG','送信中','SD','送信済','AD','承認済','CD','取消済','DD','削除済')             recon_status            ,--消込ステータス
         h.corp_code                                                                                                            corp_code               ,--企業コード
         h.deduction_chain_code                                                                                                 deduction_chain_code    ,--控除用チェーンコード
         h.cust_code                                                                                                            cust_code               ,--顧客コード
         h.condition_no                                                                                                         condition_no            ,--控除番号
         h.target_date_end                                                                                                      target_date_end         ,--対象期間TO
         DECODE(h.interface_div,'AP','控除支払','問屋支払')                                                                     interface_div           ,--連携先
         (SELECT SUM(deduction_amt) from xxcok.xxcok_deduction_num_recon n where n.recon_slip_num = h.recon_slip_num)           n_deduction_amt         ,--控除No別_控除額
         (SELECT SUM(deduction_amt) from xxcok.xxcok_deduction_item_recon i where i.recon_slip_num = h.recon_slip_num)          i_deduction_amt         ,--品目別_控除額
         (SELECT SUM(deduction_amount) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1) 
                                                                                                                                s_deduction_amount      ,--控除データ_控除額
         (SELECT NVL(SUM(deduction_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND S.STATUS = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
          (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
          (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)  deduction_amt_diff      ,--控除額異常値
         (SELECT SUM(deduction_tax) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)           n_deduction_tax         ,--控除NO別_税額
         (SELECT SUM(deduction_tax) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)          i_deduction_tax         ,--品目別_税額
         (SELECT SUM(deduction_tax_amount) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1) 
                                                                                                                                s_deduction_tax_amount  ,--控除データ_税額
         (SELECT NVL(SUM(deduction_tax_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
          (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
          (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)  deduction_tax_diff       --税額異常値
       FROM  xxcok.xxcok_deduction_recon_head h
       WHERE h.recon_status  IN ('AD','EG','SD','SG')  
-- 2023/06/14 Ver1.4 ADD Start
       AND   h.interface_div <> 'AR' --入金相殺を除く
-- 2023/06/14 Ver1.4 ADD End
       AND (  h.last_update_date >= ld_date 
             OR
             (SELECT MAX(n.last_update_date) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) >= ld_date 
             OR
             (SELECT MAX(i.last_update_date) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num) >= ld_date 
           )
       AND (  (SELECT NVL(SUM(deduction_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND S.STATUS = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
              (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
              (SELECT NVL(SUM(deduction_amt),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num) 
              <> 0
            OR
              (SELECT NVL(SUM(deduction_tax_amount),0) FROM xxcok.xxcok_sales_deduction s WHERE s.recon_slip_num = h.recon_slip_num AND s.status = 'N' AND s.source_category NOT IN ('D','O') AND s.created_by <> -1)  -
              (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num) - 
              (SELECT NVL(SUM(deduction_tax),0) FROM xxcok.xxcok_deduction_item_recon i WHERE i.recon_slip_num = h.recon_slip_num)
              <> 0
           );
    -- メインカーソルレコード型
    main_rec7  main_cur7%ROWTYPE;
--
    -- ● AP部門入力伝票ステータスが承認済で、控除消込ヘッダーのステータスが削除済み
    CURSOR main_cur8
    IS
       SELECT  
         h.creation_date                                                                                                creation_date           , --作成日
         h.deduction_recon_head_id                                                                                      deduction_recon_head_id , --控除消込ヘッダーID
         h.recon_slip_num                                                                                               recon_slip_num          , --支払伝票番号
         h.applicant                                                                                                    applicant               , --申請者
         (SELECT nvl(description,h.applicant) FROM fnd_user fu WHERE fu.user_name = h.applicant)                        applicant_name          , --申請者
         h.approver                                                                                                     approver                , --承認者
         (SELECT nvl(description,h.approver) FROM fnd_user fu WHERE fu.user_name = h.approver)                          approver_name           , --承認者
         h.recon_due_date                                                                                               recon_due_date          , --支払予定日
         h.recon_base_code                                                                                              recon_base_code         , --支払請求拠点
         h.payee_code                                                                                                   payee_code              , --支払先コード
         h.recon_status                                                                                                 recon_status_code       , --消込ステータスコード
         decode(h.recon_status,'EG','入力中','SG','送信中','SD','送信済','AD','承認済','CD','取消済','DD','削除済')     recon_status            , --消込ステータス
         h.corp_code                                                                                                    corp_code               , --企業コード
         h.deduction_chain_code                                                                                         deduction_chain_code    , --控除用チェーンコード
         h.cust_code                                                                                                    cust_code               , --顧客コード
         h.condition_no                                                                                                 condition_no            , --控除番号
         h.target_date_end                                                                                              target_date_end         , --対象期間TO
         (SELECT SUM(deduction_amt)  FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  deduction_amt           , --控除NO別_控除額(税抜)
         (SELECT SUM(deduction_tax)  FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  deduction_tax           , --控除NO別_控除額(消費税)
         (SELECT SUM(payment_amt)    FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  payment_amt             , --控除NO別_支払額(税抜)
         (SELECT SUM(payment_tax)    FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  payment_tax             , --控除NO別_支払額(消費税)
         (SELECT SUM(difference_amt) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  difference_amt          , --控除NO別_調整差額(税抜)
         (SELECT SUM(difference_tax) FROM xxcok.xxcok_deduction_num_recon n WHERE n.recon_slip_num = h.recon_slip_num)  difference_tax          , --控除NO別_調整差額(消費税)
         s.creation_date                                                                                                creation_date_s         , --部門入力作成日
         s.invoice_id                                                                                                   invoice_id              , --部門入力伝票ID
         s.wf_status                                                                                                    wf_status               , --部門入力ステータス
         s.invoice_num                                                                                                  invoice_num             , --部門入力伝票番号
         s.requestor_person_name                                                                                        requestor_person_name   , --部門入力申請者名
         s.approver_person_name                                                                                         approver_person_name      --部門入力承認者名
       FROM    xxcok.xxcok_deduction_recon_head h,
               xx03.xx03_payment_slips s
       WHERE   s.slip_type = '30000'
       AND     s.orig_invoice_num is null
       AND     s.wf_status = '80'
       AND     h.recon_slip_num = s.description
       AND     h.recon_status not in ('AD','CD','SD')
       AND    ( s.last_update_date >= ld_date 
              OR
                h.last_update_date >= ld_date 
              )
       ORDER BY DESCRIPTION;
    -- メインカーソルレコード型
    main_rec8  main_cur8%ROWTYPE;
--
--2022/06/08 1.1 add end
-- 2022/08/02 Ver1.2 ADD Start
    -- ● 差額データもしくは繰越データが複数回作成されている支払伝票
    CURSOR main_cur9
    IS
      SELECT
        ilv.recon_base_code   recon_base_code , -- 支払請求拠点
        ilv.recon_slip_num    recon_slip_num  , -- 支払伝票番号
        ilv.application_date  application_date, -- 申請日
        ilv.approval_date     approval_date   , -- 承認日
        ilv.recon_due_date    recon_due_date  , -- 支払予定日
        ilv.payee_code        payee_code      , -- 支払先コード
        ilv.invoice_number    invoice_number  , -- 問屋請求書番号
        ilv.applicant         applicant       , -- 申請者
        ilv.approver          approver          -- 承認者
      FROM
      (
        SELECT
          xdrh.recon_base_code  recon_base_code , -- 支払請求拠点
          xdrh.recon_slip_num   recon_slip_num  , -- 支払伝票番号
          xdrh.application_date application_date, -- 申請日
          xdrh.approval_date    approval_date   , -- 承認日
          xdrh.recon_due_date   recon_due_date  , -- 支払予定日
          xdrh.payee_code       payee_code      , -- 支払先コード
          xdrh.invoice_number   invoice_number  , -- 問屋請求書番号
          xdrh.applicant        applicant       , -- 申請者
          xdrh.approver         approver          -- 承認者
        FROM
          xxcok.xxcok_sales_deduction       xsd ,
          xxcok.xxcok_deduction_recon_head  xdrh
        WHERE
          xdrh.recon_status   =   'AD'                and
          xdrh.approval_date  >=  ld_date             and
          xsd.recon_slip_num  =   xdrh.recon_slip_num and
          xsd.status          =   'N'                 and
          xsd.source_category in  ('D','O')
        GROUP BY
          xdrh.recon_base_code    , -- 支払請求拠点
          xdrh.recon_slip_num     , -- 支払伝票番号
          xdrh.application_date   , -- 申請日
          xdrh.approval_date      , -- 承認日
          xdrh.recon_due_date     , -- 支払予定日
          xdrh.payee_code         , -- 支払先コード
          xdrh.invoice_number     , -- 問屋請求書番号
          xdrh.applicant          , -- 申請者
          xdrh.approver           , -- 承認者
          xsd.condition_no        , -- 控除番号
          xsd.tax_code            , -- 税コード
          xsd.customer_code_to    , -- 振替先顧客コード
-- 2023/05/25 Ver1.3 ADD Start
          xsd.base_code_to        , -- 振替先拠点コード
-- 2023/05/25 Ver1.3 ADD End
          xsd.deduction_chain_code, -- 控除用チェーンコード
          xsd.corp_code           , -- 企業コード
          xsd.item_code             -- 品目コード
        HAVING count(*) > 1
      ) ilv
      GROUP BY
        ilv.recon_base_code , -- 支払請求拠点
        ilv.recon_slip_num  , -- 支払伝票番号
        ilv.application_date, -- 申請日
        ilv.approval_date   , -- 承認日
        ilv.recon_due_date  , -- 支払予定日
        ilv.payee_code      , -- 支払先コード
        ilv.invoice_number  , -- 問屋請求書番号
        ilv.applicant       , -- 申請者
        ilv.approver          -- 承認者
      ORDER BY
        ilv.recon_base_code , -- 支払請求拠点
        ilv.recon_slip_num  ; -- 支払伝票番号
    -- メインカーソルレコード型
    main_rec9  main_cur9%ROWTYPE;
--
-- 2022/08/02 Ver1.2 ADD End
  BEGIN
--
--##################  固定ステータス初期化部 START   ###################
--
    ov_retcode := cv_status_normal;
--
--###########################  固定部 END   ############################
--
    -- グローバル変数の初期化
    gn_error_cnt  := 0;
--
    -- ===============================
    -- init部
    -- ===============================
--
    IF ( iv_process_date IS NULL ) THEN
      ld_date := xxccp_common_pkg2.get_process_date  ;
    ELSE
      ld_date := TO_DATE(iv_process_date,'YYYY/MM/DD HH24:MI:SS')  ;
    END IF;
    -- 処理業務日付出力
    FND_FILE.PUT_LINE(
      which  => FND_FILE.LOG
     ,buff   => '処理業務日付：'|| TO_CHAR(ld_date,'YYYY/MM/DD')
    );
    -- 処理業務日付の前日分からチェック対象とする
    ld_date := ld_date -1 ;
--
    -- ===============================
    -- 処理部
    -- ===============================
--
    -- データ部出力
    FOR main_rec1 IN main_cur1 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '控除消込明細情報（AP申請）の調整差額が控除額 - 支払額と一致しません。または調整差額(税額)が控除額(税額) - 支払額(税額)と一致しません。'     || CHR(10) ||
                   '  支払請求拠点:'          || main_rec1.recon_base_code                        || CHR(10) ||  -- 支払請求拠点       
                   '  支払伝票番号:'          || main_rec1.recon_slip_num                         || CHR(10) ||  -- 支払伝票番号       
                   '  消込ステータス:'        || main_rec1.recon_status                           || CHR(10) ||  -- 消込ステータス     
                   '  申請者:'                || main_rec1.applicant                              || CHR(10) ||  -- 申請者             
                   '  申請日:'                || TO_CHAR(main_rec1.application_date,'YYYY/MM/DD') || CHR(10) ||  -- 申請日             
                   '  承認者:'                || main_rec1.approver                               || CHR(10) ||  -- 承認者             
                   '  承認日:'                || TO_CHAR(main_rec1.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- 承認日             
                   '  支払先:'                || main_rec1.payee_code                             || CHR(10) ||  -- 支払先             
                   '  請求書日付:'            || TO_CHAR(main_rec1.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- 請求書日付         
                   '  支払予定日:'            || TO_CHAR(main_rec1.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- 支払予定日         
                   '  連携先:'                || main_rec1.interface_div                          || CHR(10) ||  -- 連携先             
                   '  GL記帳日:'              || TO_CHAR(main_rec1.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL記帳日           
                   '  条件_企業:'             || main_rec1.corp_code                              || CHR(10) ||  -- 条件_企業          
                   '  条件_控除用チェーン:'   || main_rec1.deduction_chain_code_c                 || CHR(10) ||  -- 条件_控除用チェーン
                   '  条件_顧客:'             || main_rec1.cust_code                              || CHR(10) ||  -- 条件_顧客          
                   '  条件_控除番号:'         || main_rec1.condition_no                           || CHR(10) ||  -- 条件_控除番号      
                   '  条件_対象データ種類:'   || main_rec1.target_data_type                       || CHR(10) ||  -- 条件_対象データ種類
                   '  条件_対象期間TO:'       || main_rec1.target_date_end                        || CHR(10) ||  -- 条件_対象期間TO    
                   '  条件_受領請求書番号:'   || main_rec1.invoice_number                         || CHR(10) ||  -- 条件_受領請求書番号
                   '  控除用チェーン:'        || main_rec1.deduction_chain_code                   || CHR(10) ||  -- 控除用チェーン     
                   '  控除額_本体額:'         || main_rec1.deduction_amt                          || CHR(10) ||  -- 控除額_本体額      
                   '  支払額_本体額:'         || main_rec1.payment_amt                            || CHR(10) ||  -- 支払額_本体額      
                   '  調整差額_本体額:'       || main_rec1.difference_amt                         || CHR(10) ||  -- 調整差額_本体額    
                   '  控除額_税額:'           || main_rec1.deduction_tax                          || CHR(10) ||  -- 控除額_税額        
                   '  支払額_税額:'           || main_rec1.payment_tax                            || CHR(10) ||  -- 支払額_税額        
                   '  調整差額_税額:'         || main_rec1.difference_tax                         || CHR(10)     -- 調整差額_税額      
      );
    END LOOP;
--
    FOR main_rec2 IN main_cur2 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '控除No別消込情報の調整差額が控除額 - 支払額と一致しません。または調整差額(税額)が控除額(税額) - 支払額(税額)と一致しません。'   || CHR(10) ||
                   '  支払請求拠点:'          || main_rec2.recon_base_code                        || CHR(10) ||  -- 支払請求拠点       
                   '  支払伝票番号:'          || main_rec2.recon_slip_num                         || CHR(10) ||  -- 支払伝票番号       
                   '  消込ステータス:'        || main_rec2.recon_status                           || CHR(10) ||  -- 消込ステータス     
                   '  申請者:'                || main_rec2.applicant                              || CHR(10) ||  -- 申請者             
                   '  申請日:'                || TO_CHAR(main_rec2.application_date,'YYYY/MM/DD') || CHR(10) ||  -- 申請日             
                   '  承認者:'                || main_rec2.approver                               || CHR(10) ||  -- 承認者             
                   '  承認日:'                || TO_CHAR(main_rec2.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- 承認日             
                   '  支払先:'                || main_rec2.payee_code                             || CHR(10) ||  -- 支払先             
                   '  請求書日付:'            || TO_CHAR(main_rec2.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- 請求書日付         
                   '  支払予定日:'            || TO_CHAR(main_rec2.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- 支払予定日         
                   '  連携先:'                || main_rec2.interface_div                          || CHR(10) ||  -- 連携先             
                   '  GL記帳日:'              || TO_CHAR(main_rec2.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL記帳日           
                   '  条件_企業:'             || main_rec2.corp_code                              || CHR(10) ||  -- 条件_企業          
                   '  条件_控除用チェーン:'   || main_rec2.deduction_chain_code_c                 || CHR(10) ||  -- 条件_控除用チェーン
                   '  条件_顧客:'             || main_rec2.cust_code                              || CHR(10) ||  -- 条件_顧客          
                   '  条件_控除番号:'         || main_rec2.condition_no_c                         || CHR(10) ||  -- 条件_控除番号      
                   '  条件_対象データ種類:'   || main_rec2.target_data_type                       || CHR(10) ||  -- 条件_対象データ種類
                   '  条件_対象期間TO:'       || main_rec2.target_date_end                        || CHR(10) ||  -- 条件_対象期間TO    
                   '  条件_受領請求書番号:'   || main_rec2.invoice_number                         || CHR(10) ||  -- 条件_受領請求書番号
                   '  控除用チェーン:'        || main_rec2.deduction_chain_code                   || CHR(10) ||  -- 控除用チェーン     
                   '  控除番号:'              || main_rec2.condition_no                           || CHR(10) ||  -- 控除番号           
                   '  データ種類:'            || main_rec2.data_type                              || CHR(10) ||  -- データ種類         
                   '  支払時税コード:'        || main_rec2.payment_tax_code                       || CHR(10) ||  -- 支払時税コード     
                   '  控除額_本体額:'         || main_rec2.deduction_amt                          || CHR(10) ||  -- 控除額_本体額      
                   '  支払額_本体額:'         || main_rec2.payment_amt                            || CHR(10) ||  -- 支払額_本体額      
                   '  調整差額_本体額:'       || main_rec2.difference_amt                         || CHR(10) ||  -- 調整差額_本体額    
                   '  控除額_税額:'           || main_rec2.deduction_tax                          || CHR(10) ||  -- 控除額_税額        
                   '  支払額_税額:'           || main_rec2.payment_tax                            || CHR(10) ||  -- 支払額_税額        
                   '  調整差額_税額:'         || main_rec2.difference_tax                         || CHR(10)     -- 調整差額_税額      
      );
    END LOOP;
--
    FOR main_rec3 IN main_cur3 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '控除消込明細情報（問屋未収）の調整差額が控除額 - 支払額と一致しません。または調整差額(税額)が控除額(税額) - 支払額(税額)と一致しません。'   || CHR(10) ||
                   '  支払請求拠点:'          || main_rec3.recon_base_code                        || CHR(10) ||  -- 支払請求拠点       
                   '  支払伝票番号:'          || main_rec3.recon_slip_num                         || CHR(10) ||  -- 支払伝票番号       
                   '  消込ステータス:'        || main_rec3.recon_status                           || CHR(10) ||  -- 消込ステータス     
                   '  申請者:'                || main_rec3.applicant                              || CHR(10) ||  -- 申請者             
                   '  申請日:'                || TO_CHAR(main_rec3.application_date,'YYYY/MM/DD') || CHR(10) ||  -- 申請日             
                   '  承認者:'                || main_rec3.approver                               || CHR(10) ||  -- 承認者             
                   '  承認日:'                || TO_CHAR(main_rec3.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- 承認日             
                   '  支払先:'                || main_rec3.payee_code                             || CHR(10) ||  -- 支払先             
                   '  請求書日付:'            || TO_CHAR(main_rec3.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- 請求書日付         
                   '  支払予定日:'            || TO_CHAR(main_rec3.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- 支払予定日         
                   '  連携先:'                || main_rec3.interface_div                          || CHR(10) ||  -- 連携先             
                   '  GL記帳日:'              || TO_CHAR(main_rec3.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL記帳日           
                   '  条件_企業:'             || main_rec3.corp_code                              || CHR(10) ||  -- 条件_企業          
                   '  条件_控除用チェーン:'   || main_rec3.deduction_chain_code_c                 || CHR(10) ||  -- 条件_控除用チェーン
                   '  条件_顧客:'             || main_rec3.cust_code                              || CHR(10) ||  -- 条件_顧客          
                   '  条件_控除番号:'         || main_rec3.condition_no                           || CHR(10) ||  -- 条件_控除番号      
                   '  条件_対象データ種類:'   || main_rec3.target_data_type                       || CHR(10) ||  -- 条件_対象データ種類
                   '  条件_対象期間TO:'       || main_rec3.target_date_end                        || CHR(10) ||  -- 条件_対象期間TO    
                   '  条件_受領請求書番号:'   || main_rec3.invoice_number                         || CHR(10) ||  -- 条件_受領請求書番号
                   '  控除用チェーン:'        || main_rec3.deduction_chain_code                   || CHR(10) ||  -- 控除用チェーン     
                   '  控除額_本体額:'         || main_rec3.deduction_amt                          || CHR(10) ||  -- 控除額_本体額      
                   '  支払額_本体額:'         || main_rec3.payment_amt                            || CHR(10) ||  -- 支払額_本体額      
                   '  調整差額_本体額:'       || main_rec3.difference_amt                         || CHR(10) ||  -- 調整差額_本体額    
                   '  控除額_税額:'           || main_rec3.deduction_tax                          || CHR(10) ||  -- 控除額_税額        
                   '  支払額_税額:'           || main_rec3.payment_tax                            || CHR(10) ||  -- 支払額_税額        
                   '  調整差額_税額:'         || main_rec3.difference_tax                         || CHR(10)     -- 調整差額_税額      
      );
    END LOOP;
--
    FOR main_rec4 IN main_cur4 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '商品別突合情報の調整差額が控除額 - 支払額と一致しません。または調整差額(税額)が控除額(税額) - 支払額(税額)と一致しません。'   || CHR(10) ||
                   '  支払請求拠点:'          || main_rec4.recon_base_code                        || CHR(10) ||  -- 支払請求拠点       
                   '  支払伝票番号:'          || main_rec4.recon_slip_num                         || CHR(10) ||  -- 支払伝票番号       
                   '  消込ステータス:'        || main_rec4.recon_status                           || CHR(10) ||  -- 消込ステータス     
                   '  申請者:'                || main_rec4.applicant                              || CHR(10) ||  -- 申請者             
                   '  申請日:'                || TO_CHAR(main_rec4.application_date,'YYYY/MM/DD') || CHR(10) ||  -- 申請日             
                   '  承認者:'                || main_rec4.approver                               || CHR(10) ||  -- 承認者             
                   '  承認日:'                || TO_CHAR(main_rec4.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- 承認日             
                   '  支払先:'                || main_rec4.payee_code                             || CHR(10) ||  -- 支払先             
                   '  請求書日付:'            || TO_CHAR(main_rec4.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- 請求書日付         
                   '  支払予定日:'            || TO_CHAR(main_rec4.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- 支払予定日         
                   '  連携先:'                || main_rec4.interface_div                          || CHR(10) ||  -- 連携先             
                   '  GL記帳日:'              || TO_CHAR(main_rec4.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL記帳日           
                   '  条件_企業:'             || main_rec4.corp_code                              || CHR(10) ||  -- 条件_企業          
                   '  条件_控除用チェーン:'   || main_rec4.deduction_chain_code_c                 || CHR(10) ||  -- 条件_控除用チェーン
                   '  条件_顧客:'             || main_rec4.cust_code                              || CHR(10) ||  -- 条件_顧客          
                   '  条件_控除番号:'         || main_rec4.condition_no                           || CHR(10) ||  -- 条件_控除番号      
                   '  条件_対象データ種類:'   || main_rec4.target_data_type                       || CHR(10) ||  -- 条件_対象データ種類
                   '  条件_対象期間TO:'       || main_rec4.target_date_end                        || CHR(10) ||  -- 条件_対象期間TO    
                   '  条件_受領請求書番号:'   || main_rec4.invoice_number                         || CHR(10) ||  -- 条件_受領請求書番号
                   '  控除用チェーン:'        || main_rec4.deduction_chain_code                   || CHR(10) ||  -- 控除用チェーン     
                   '  品目:'                  || main_rec4.item_code                              || CHR(10) ||  -- 品目               
                   '  消費税コード:'          || main_rec4.tax_code                               || CHR(10) ||  -- 消費税コード       
                   '  控除額_本体額:'         || main_rec4.deduction_amt                          || CHR(10) ||  -- 控除額_本体額      
                   '  支払額_本体額:'         || main_rec4.payment_amt                            || CHR(10) ||  -- 支払額_本体額      
                   '  調整差額_本体額:'       || main_rec4.difference_amt                         || CHR(10) ||  -- 調整差額_本体額    
                   '  控除額_税額:'           || main_rec4.deduction_tax                          || CHR(10) ||  -- 控除額_税額        
                   '  支払額_税額:'           || main_rec4.payment_tax                            || CHR(10) ||  -- 支払額_税額        
                   '  調整差額_税額:'         || main_rec4.difference_tax                         || CHR(10)     -- 調整差額_税額      
      );
    END LOOP;
--
    FOR main_rec5 IN main_cur5 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '控除No別消込情報の支払額と控除消込明細の支払額が一致しません。または控除No別消込情報の支払税額と控除消込明細の支払税額が一致しません。'   || CHR(10) ||
                   '  支払請求拠点:'          || main_rec5.recon_base_code                        || CHR(10) ||  -- 支払請求拠点       
                   '  支払伝票番号:'          || main_rec5.recon_slip_num                         || CHR(10) ||  -- 支払伝票番号       
                   '  消込ステータス:'        || main_rec5.recon_status                           || CHR(10) ||  -- 消込ステータス     
                   '  申請者:'                || main_rec5.applicant                              || CHR(10) ||  -- 申請者             
                   '  申請日:'                || TO_CHAR(main_rec5.application_date,'YYYY/MM/DD') || CHR(10) ||  -- 申請日             
                   '  承認者:'                || main_rec5.approver                               || CHR(10) ||  -- 承認者             
                   '  承認日:'                || TO_CHAR(main_rec5.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- 承認日             
                   '  支払先:'                || main_rec5.payee_code                             || CHR(10) ||  -- 支払先             
                   '  請求書日付:'            || TO_CHAR(main_rec5.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- 請求書日付         
                   '  支払予定日:'            || TO_CHAR(main_rec5.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- 支払予定日         
                   '  連携先:'                || main_rec5.interface_div                          || CHR(10) ||  -- 連携先             
                   '  GL記帳日:'              || TO_CHAR(main_rec5.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL記帳日           
                   '  条件_企業:'             || main_rec5.corp_code                              || CHR(10) ||  -- 条件_企業          
                   '  条件_控除用チェーン:'   || main_rec5.deduction_chain_code_c                 || CHR(10) ||  -- 条件_控除用チェーン
                   '  条件_顧客:'             || main_rec5.cust_code                              || CHR(10) ||  -- 条件_顧客          
                   '  条件_控除番号:'         || main_rec5.condition_no                           || CHR(10) ||  -- 条件_控除番号      
                   '  条件_対象データ種類:'   || main_rec5.target_data_type                       || CHR(10) ||  -- 条件_対象データ種類
                   '  条件_対象期間TO:'       || main_rec5.target_date_end                        || CHR(10) ||  -- 条件_対象期間TO    
                   '  条件_受領請求書番号:'   || main_rec5.invoice_number                         || CHR(10) ||  -- 条件_受領請求書番号
--2022/06/08 1.1 add start
                   '  控除用チェーン:'        || main_rec5.deduction_chain_code                   || CHR(10) ||  -- 控除用チェーン     
--2022/06/08 1.1 add end
                   '  控除額_本体額:'         || main_rec5.deduction_amt                          || CHR(10) ||  -- 控除額_本体額       
                   '  控除額_税額:'           || main_rec5.deduction_tax                          || CHR(10) ||  -- 控除額_税額         
                   '  支払額_本体額:'         || main_rec5.payment_amt                            || CHR(10) ||  -- 支払額_本体額       
                   '  支払額_税額:'           || main_rec5.payment_tax                            || CHR(10) ||  -- 支払額_税額         
                   '  調整差額_本体額:'       || main_rec5.difference_amt                         || CHR(10) ||  -- 調整差額_本体額     
                   '  調整差額_税額:'         || main_rec5.difference_tax                         || CHR(10) ||  -- 調整差額_税額       
                   '  支払額_本体額_控除No別:'|| main_rec5.sum_payment_amt                        || CHR(10) ||  -- 支払額_本体額_控除No別
                   '  支払額_税額_控除No別:'  || main_rec5.sum_payment_tax                        || CHR(10)     -- 支払額_税額_控除No別  
      );
    END LOOP;
--
    FOR main_rec6 IN main_cur6 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '商品別突合情報の支払額と控除消込明細の支払額が一致しません。または商品別突合情報の支払税額と控除消込明細の支払税額が一致しません。'   || CHR(10) ||
                   '  支払請求拠点:'          || main_rec6.recon_base_code                        || CHR(10) ||  -- 支払請求拠点       
                   '  支払伝票番号:'          || main_rec6.recon_slip_num                         || CHR(10) ||  -- 支払伝票番号       
                   '  消込ステータス:'        || main_rec6.recon_status                           || CHR(10) ||  -- 消込ステータス     
                   '  申請者:'                || main_rec6.applicant                              || CHR(10) ||  -- 申請者             
                   '  申請日:'                || TO_CHAR(main_rec6.application_date,'YYYY/MM/DD') || CHR(10) ||  -- 申請日             
                   '  承認者:'                || main_rec6.approver                               || CHR(10) ||  -- 承認者             
                   '  承認日:'                || TO_CHAR(main_rec6.approval_date,'YYYY/MM/DD')    || CHR(10) ||  -- 承認日             
                   '  支払先:'                || main_rec6.payee_code                             || CHR(10) ||  -- 支払先             
                   '  請求書日付:'            || TO_CHAR(main_rec6.invoice_date,'YYYY/MM/DD')     || CHR(10) ||  -- 請求書日付         
                   '  支払予定日:'            || TO_CHAR(main_rec6.recon_due_date,'YYYY/MM/DD')   || CHR(10) ||  -- 支払予定日         
                   '  連携先:'                || main_rec6.interface_div                          || CHR(10) ||  -- 連携先             
                   '  GL記帳日:'              || TO_CHAR(main_rec6.gl_date,'YYYY/MM/DD')          || CHR(10) ||  -- GL記帳日           
                   '  条件_企業:'             || main_rec6.corp_code                              || CHR(10) ||  -- 条件_企業          
                   '  条件_控除用チェーン:'   || main_rec6.deduction_chain_code_c                 || CHR(10) ||  -- 条件_控除用チェーン
                   '  条件_顧客:'             || main_rec6.cust_code                              || CHR(10) ||  -- 条件_顧客          
                   '  条件_控除番号:'         || main_rec6.condition_no                           || CHR(10) ||  -- 条件_控除番号      
                   '  条件_対象データ種類:'   || main_rec6.target_data_type                       || CHR(10) ||  -- 条件_対象データ種類
                   '  条件_対象期間TO:'       || main_rec6.target_date_end                        || CHR(10) ||  -- 条件_対象期間TO    
                   '  条件_受領請求書番号:'   || main_rec6.invoice_number                         || CHR(10) ||  -- 条件_受領請求書番号
--2022/06/08 1.1 add start
                   '  控除用チェーン:'        || main_rec6.deduction_chain_code                   || CHR(10) ||  -- 控除用チェーン     
--2022/06/08 1.1 add end
                   '  控除額_本体額:'         || main_rec6.deduction_amt                          || CHR(10) ||  -- 控除額_本体額        
                   '  控除額_税額:'           || main_rec6.deduction_tax                          || CHR(10) ||  -- 控除額_税額          
                   '  支払額_本体額:'         || main_rec6.payment_amt                            || CHR(10) ||  -- 支払額_本体額        
                   '  支払額_税額:'           || main_rec6.payment_tax                            || CHR(10) ||  -- 支払額_税額          
                   '  調整差額_本体額:'       || main_rec6.difference_amt                         || CHR(10) ||  -- 調整差額_本体額      
                   '  調整差額_税額:'         || main_rec6.difference_tax                         || CHR(10) ||  -- 調整差額_税額        
                   '  支払額_本体額_商品別:'  || main_rec6.sum_payment_amt                        || CHR(10) ||  -- 支払額_本体額_商品別 
                   '  支払額_税額_商品別:'    || main_rec6.sum_payment_tax                        || CHR(10)     -- 支払額_税額_商品別   
      );
    END LOOP;
--
--2022/06/08 1.1 add start
--
    FOR main_rec7 IN main_cur7 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '販売控除情報の控除額が控除No別消込情報の控除額 + 商品別突合情報の控除額と一致しません。または販売控除情報の税額が控除No別消込情報の税額 + 商品別突合情報の税額と一致しません。'   || CHR(10) ||
                   '  作成日:'                      || TO_CHAR(main_rec7.creation_date,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||  -- 作成日
                   '  控除消込ヘッダーID:'          || main_rec7.deduction_recon_head_id                        || CHR(10) ||  -- 控除消込ヘッダーID
                   '  支払伝票番号:'                || main_rec7.recon_slip_num                                 || CHR(10) ||  -- 支払伝票番号
                   '  申請者:'                      || main_rec7.applicant                                      || CHR(10) ||  -- 申請者
                   '  申請者名:'                    || main_rec7.applicant_name                                 || CHR(10) ||  -- 申請者名
                   '  承認者:'                      || main_rec7.approver                                       || CHR(10) ||  -- 承認者
                   '  承認者名:'                    || main_rec7.approver_name                                  || CHR(10) ||  -- 承認者名
                   '  支払予定日:'                  || TO_CHAR(main_rec7.recon_due_date,'YYYY/MM/DD')           || CHR(10) ||  -- 支払予定日
                   '  支払請求拠点:'                || main_rec7.recon_base_code                                || CHR(10) ||  -- 支払請求拠点
                   '  支払先コード:'                || main_rec7.payee_code                                     || CHR(10) ||  -- 支払先コード
                   '  消込ステータスコード:'        || main_rec7.recon_status_code                              || CHR(10) ||  -- 消込ステータスコード
                   '  消込ステータス:'              || main_rec7.recon_status                                   || CHR(10) ||  -- 消込ステータス
                   '  企業コード:'                  || main_rec7.corp_code                                      || CHR(10) ||  -- 企業コード
                   '  控除用チェーンコード:'        || main_rec7.deduction_chain_code                           || CHR(10) ||  -- 控除用チェーンコード
                   '  顧客コード:'                  || main_rec7.cust_code                                      || CHR(10) ||  -- 顧客コード
                   '  控除番号:'                    || main_rec7.condition_no                                   || CHR(10) ||  -- 控除番号
                   '  対象期間TO:'                  || TO_CHAR(main_rec7.target_date_end,'YYYY/MM/DD')          || CHR(10) ||  -- 対象期間TO
                   '  連携先:'                      || main_rec7.interface_div                                  || CHR(10) ||  -- 連携先
                   '  控除NO別_控除額(税抜):'       || main_rec7.n_deduction_amt                                || CHR(10) ||  -- 控除NO別_控除額(税抜)
                   '  品目別_控除額(税抜):'         || main_rec7.i_deduction_amt                                || CHR(10) ||  -- 品目別_控除額(税抜)
                   '  控除データ_控除額(税抜):'     || main_rec7.s_deduction_amount                             || CHR(10) ||  -- 控除データ_控除額(税抜)
                   '  異常値(税抜):'                || main_rec7.deduction_amt_diff                             || CHR(10) ||  -- 異常値(税抜)
                   '  控除NO別_控除額(消費税):'     || main_rec7.n_deduction_tax                                || CHR(10) ||  -- 控除NO別_控除額(消費税)
                   '  品目別_控除額(消費税):'       || main_rec7.i_deduction_tax                                || CHR(10) ||  -- 品目別_控除額(消費税)
                   '  控除データ_控除額(消費税):'   || main_rec7.s_deduction_tax_amount                         || CHR(10) ||  -- 控除データ_控除額(消費税)
                   '  税額異常値(消費税):'          || main_rec7.deduction_tax_diff                             || CHR(10)     -- 税額異常値(消費税)
      );
    END LOOP;
--
    FOR main_rec8 IN main_cur8 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => 'AP部門入力伝票のステータスが承認済で、控除消込ヘッダー情報のステータスが削除済みのデータを検知しました。'   || CHR(10) ||
                   '  作成日:'                      || TO_CHAR(main_rec8.creation_date,'YYYY/MM/DD HH24:MI:SS')   || CHR(10) ||  -- 作成日
                   '  控除消込ヘッダーID:'          || main_rec8.deduction_recon_head_id                          || CHR(10) ||  -- 控除消込ヘッダーID
                   '  支払伝票番号:'                || main_rec8.recon_slip_num                                   || CHR(10) ||  -- 支払伝票番号
                   '  申請者:'                      || main_rec8.applicant                                        || CHR(10) ||  -- 申請者
                   '  申請者名:'                    || main_rec8.applicant_name                                   || CHR(10) ||  -- 申請者名
                   '  承認者:'                      || main_rec8.approver                                         || CHR(10) ||  -- 承認者
                   '  承認者名:'                    || main_rec8.approver_name                                    || CHR(10) ||  -- 承認者名
                   '  支払予定日:'                  || TO_CHAR(main_rec8.recon_due_date,'YYYY/MM/DD')             || CHR(10) ||  -- 支払予定日
                   '  支払請求拠点:'                || main_rec8.recon_base_code                                  || CHR(10) ||  -- 支払請求拠点
                   '  支払先コード:'                || main_rec8.payee_code                                       || CHR(10) ||  -- 支払先コード
                   '  消込ステータスコード:'        || main_rec8.recon_status_code                                || CHR(10) ||  -- 消込ステータスコード
                   '  消込ステータス:'              || main_rec8.recon_status                                     || CHR(10) ||  -- 消込ステータス
                   '  企業コード:'                  || main_rec8.corp_code                                        || CHR(10) ||  -- 企業コード
                   '  控除用チェーンコード:'        || main_rec8.deduction_chain_code                             || CHR(10) ||  -- 控除用チェーンコード
                   '  顧客コード:'                  || main_rec8.cust_code                                        || CHR(10) ||  -- 顧客コード
                   '  控除番号:'                    || main_rec8.condition_no                                     || CHR(10) ||  -- 控除番号
                   '  対象期間TO:'                  || TO_CHAR(main_rec8.target_date_end,'YYYY/MM/DD')            || CHR(10) ||  -- 対象期間TO
                   '  控除NO別_控除額(税抜):'       || main_rec8.deduction_amt                                    || CHR(10) ||  -- 控除NO別_控除額(税抜)
                   '  控除NO別_控除額(消費税):'     || main_rec8.deduction_tax                                    || CHR(10) ||  -- 控除NO別_控除額(消費税)
                   '  控除NO別_支払額(税抜):'       || main_rec8.payment_amt                                      || CHR(10) ||  -- 控除NO別_支払額(税抜)
                   '  控除NO別_支払額(消費税):'     || main_rec8.payment_tax                                      || CHR(10) ||  -- 控除NO別_支払額(消費税)
                   '  控除NO別_調整差額(税抜):'     || main_rec8.difference_amt                                   || CHR(10) ||  -- 控除NO別_調整差額(税抜)
                   '  控除NO別_調整差額(消費税):'   || main_rec8.difference_tax                                   || CHR(10) ||  -- 控除NO別_調整差額(消費税)
                   '  部門入力作成日:'              || TO_CHAR(main_rec8.creation_date_s,'YYYY/MM/DD HH24:MI:SS') || CHR(10) ||  -- 部門入力作成日
                   '  部門入力伝票ID:'              || main_rec8.invoice_id                                       || CHR(10) ||  -- 部門入力伝票ID
                   '  部門入力ステータス:'          || main_rec8.wf_status                                        || CHR(10) ||  -- 部門入力ステータス
                   '  部門入力伝票番号:'            || main_rec8.invoice_num                                      || CHR(10) ||  -- 部門入力伝票番号
                   '  部門入力申請者名:'            || main_rec8.requestor_person_name                            || CHR(10) ||  -- 部門入力申請者名
                   '  部門入力承認者名:'            || main_rec8.approver_person_name                             || CHR(10)     -- 部門入力承認者名
      );
    END LOOP;
--2022/06/08 1.1 add end
-- 2022/08/02 Ver1.2 ADD Start
--
    FOR main_rec9 IN main_cur9 LOOP
      --件数セット
      gn_error_cnt := gn_error_cnt + 1;
      --
      FND_FILE.PUT_LINE(
         which  => FND_FILE.OUTPUT
        ,buff   => '差額データもしくは繰越データが複数回作成されている支払伝票を検知しました。'   || CHR(10) ||
                   '  支払請求拠点:'                || main_rec9.recon_base_code                        || CHR(10) ||  -- 支払請求拠点
                   '  支払伝票番号:'                || main_rec9.recon_slip_num                         || CHR(10) ||  -- 支払伝票番号
                   '  申請日:'                      || TO_CHAR(main_rec9.application_date,'YYYY/MM/DD') || CHR(10) ||  -- 申請日
                   '  承認日:'                      || TO_CHAR(main_rec9.approval_date   ,'YYYY/MM/DD') || CHR(10) ||  -- 承認日
                   '  支払予定日:'                  || TO_CHAR(main_rec9.recon_due_date  ,'YYYY/MM/DD') || CHR(10) ||  -- 支払予定日
                   '  支払先コード:'                || main_rec9.payee_code                             || CHR(10) ||  -- 支払先コード
                   '  問屋請求書番号:'              || main_rec9.invoice_number                         || CHR(10) ||  -- 問屋請求書番号
                   '  申請者:'                      || main_rec9.applicant                              || CHR(10) ||  -- 申請者
                   '  承認者:'                      || main_rec9.approver                               || CHR(10)     -- 承認者
      );
    END LOOP;
--
-- 2022/08/02 Ver1.2 ADD End
    IF ( gn_error_cnt > 0 ) THEN
      ov_retcode := cv_status_error;
    END IF;
--
  EXCEPTION
      -- *** 任意で例外処理を記述する ****
      -- カーソルのクローズをここに記述する
--
--#################################  固定例外処理部 START   ###################################
--
    -- *** 処理部共通例外ハンドラ ***
    WHEN global_process_expt THEN
      ov_errmsg  := lv_errmsg;
      ov_errbuf  := SUBSTRB(cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||lv_errbuf,1,5000);
      ov_retcode := cv_status_error;
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      ov_errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      ov_retcode := cv_status_error;
--
--####################################  固定部 END   ##########################################
--
  END submain;
--
  /**********************************************************************************
   * Procedure Name   : main
   * Description      : コンカレント実行ファイル登録プロシージャ
   **********************************************************************************/
--
  PROCEDURE main(
    errbuf                OUT VARCHAR2      --   エラー・メッセージ  --# 固定 #
   ,retcode               OUT VARCHAR2      --   リターン・コード    --# 固定 #
   ,iv_process_date       IN  VARCHAR2      --   業務日付
  )
--
--###########################  固定部 START   ###########################
--
  IS
--
    -- ===============================
    -- 固定ローカル定数
    -- ===============================
    cv_prg_name        CONSTANT VARCHAR2(100) := 'main';             -- プログラム名
--
    cv_error_rec_msg   CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90002'; -- エラー件数メッセージ
    cv_normal_msg      CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90004'; -- 正常終了メッセージ
    cv_error_msg       CONSTANT VARCHAR2(100) := 'APP-XXCCP1-90006'; -- エラー終了全ロールバック
    cv_cnt_token       CONSTANT VARCHAR2(10)  := 'COUNT';            -- 件数メッセージ用トークン名
    -- ===============================
    -- ローカル変数
    -- ===============================
    lv_errbuf          VARCHAR2(5000);  -- エラー・メッセージ
    lv_retcode         VARCHAR2(1);     -- リターン・コード
    lv_errmsg          VARCHAR2(5000);  -- ユーザー・エラー・メッセージ
    lv_message_code    VARCHAR2(100);   -- 終了メッセージコード
    --
  BEGIN
--
--###########################  固定部 START   #####################################################
--
    -- 固定出力
    -- コンカレントヘッダメッセージ出力関数の呼び出し
    xxccp_common_pkg.put_log_header(
       iv_which   => 'LOG'
      ,ov_retcode => lv_retcode
      ,ov_errbuf  => lv_errbuf
      ,ov_errmsg  => lv_errmsg
    );
    --
    IF (lv_retcode = cv_status_error) THEN
      RAISE global_api_others_expt;
    END IF;
    --
--###########################  固定部 END   #############################
--
    -- ===============================================
    -- submainの呼び出し（実際の処理はsubmainで行う）
    -- ===============================================
    submain(
       iv_process_date                             -- 業務日付
      ,lv_errbuf   -- エラー・メッセージ           --# 固定 #
      ,lv_retcode  -- リターン・コード             --# 固定 #
      ,lv_errmsg   -- ユーザー・エラー・メッセージ --# 固定 #
    );
--
    --エラー出力
    IF (lv_retcode = cv_status_error) THEN
      --空行挿入
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => ''
      );
      FND_FILE.PUT_LINE(
         which  => FND_FILE.LOG
        ,buff   => lv_errbuf --エラーメッセージ
      );
    END IF;
    --空行挿入
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => ''
    );
    --エラー件数出力
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => cv_error_rec_msg
                    ,iv_token_name1  => cv_cnt_token
                    ,iv_token_value1 => TO_CHAR(gn_error_cnt)
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --
    --終了メッセージ
    IF (lv_retcode = cv_status_normal) THEN
      lv_message_code := cv_normal_msg;
    ELSIF(lv_retcode = cv_status_error) THEN
      lv_message_code := cv_error_msg;
    END IF;
    --
    gv_out_msg := xxccp_common_pkg.get_msg(
                     iv_application  => cv_appl_short_name
                    ,iv_name         => lv_message_code
                   );
    FND_FILE.PUT_LINE(
       which  => FND_FILE.LOG
      ,buff   => gv_out_msg
    );
    --ステータスセット
    retcode := lv_retcode;
--
  EXCEPTION
    -- *** 共通関数OTHERS例外ハンドラ ***
    WHEN global_api_others_expt THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
    -- *** OTHERS例外ハンドラ ***
    WHEN OTHERS THEN
      errbuf  := cv_pkg_name||cv_msg_cont||cv_prg_name||cv_msg_part||SQLERRM;
      retcode := cv_status_error;
  END main;
--
--###########################  固定部 END   #######################################################
--
END XXCCP003A05C;
/
