/*************************************************************************
 * 
 * View  Name      : XXSKZ_在庫情報_基本_V
 * Description     : XXSKZ_在庫情報_基本_V
 * MD.070          : 
 * Version         : 1.0
 * 
 * Change Record
 * ------------- ----- ------------ -------------------------------------
 *  Date          Ver.  Editor       Description
 * ------------- ----- ------------ -------------------------------------
 *  2012/11/27    1.0   SCSK 月野    初回作成
 ************************************************************************/
CREATE OR REPLACE VIEW APPS.XXSKZ_在庫情報_基本_V
(
 当月
,名義コード
,名義
,倉庫コード
,倉庫名
,保管場所コード
,保管場所名
,保管場所略称
,商品区分
,商品区分名
,品目区分
,品目区分名
,群コード
,品目
,品目名
,品目略称
,ロットNO
,製造年月日
,固有記号
,賞味期限
,月首在庫数
,当月入庫数
,当月出庫数
,当月入庫予定数
,当月出庫予定数
,月末在庫数
,棚卸ケース数
,棚卸バラ数
,翌月入庫数
,翌月出庫数
,現在庫数
,入庫予定数
,出庫予定数
,引当可能数
)
AS
SELECT
         PRD.yyyymm                                         yyyymm              --当月
        ,IWM.attribute1                                     cust_stc_whse       --名義コード
        ,FLV01.meaning                                      cust_stc_whse_name  --名義
        ,STRN.whse_code                                     whse_code           --倉庫コード
        ,IWM.whse_name                                      whse_name           --倉庫名
        ,STRN.location                                      location            --保管場所コード
        ,ILOC.description                                   loct_name           --保管場所名
        ,ILOC.short_name                                    loct_s_name         --保管場所略称
        ,PRODC.prod_class_code                              prod_class_code     --商品区分
        ,PRODC.prod_class_name                              prod_class_name     --商品区分名
        ,ITEMC.item_class_code                              item_class_code     --品目区分
        ,ITEMC.item_class_name                              item_class_name     --品目区分名
        ,CROWD.crowd_code                                   crowd_code          --群コード
        ,ITEM.item_no                                       item_code           --品目
        ,ITEM.item_name                                     item_name           --品目名
        ,ITEM.item_short_name                               item_s_name         --品目略称
        ,NVL( DECODE( ILM.lot_no, 'DEFAULTLOT', '0', ILM.lot_no ), '0' )
                                                            lot_no              --ロットNo('DEFALTLOT'、ロット未割当は'0')
        ,CASE WHEN ITEM.lot_ctl = 1 THEN ILM.attribute1  --ロット管理品   →製造年月日を取得
              ELSE                       NULL            --非ロット管理品 →NULL
         END                                                lot_date            --製造年月日
        ,CASE WHEN ITEM.lot_ctl = 1 THEN ILM.attribute2  --ロット管理品   →ロットNOを取得
              ELSE                       NULL            --非ロット管理品 →NULL
         END                                                lot_sign            --固有記号
        ,CASE WHEN ITEM.lot_ctl = 1 THEN ILM.attribute3  --ロット管理品   →ロットNOを取得
              ELSE                       NULL            --非ロット管理品 →NULL
         END                                                best_bfr_date       --賞味期限
        ,NVL( STRN.m_start_qty     , 0 )                    m_start_qty         --月首在庫数
        ,NVL( STRN.this_in_qty     , 0 )                    this_in_qty         --当月入庫数
        ,NVL( STRN.this_out_qty    , 0 )                    this_out_qty        --当月出庫数
        ,NVL( STRN.this_sch_in_qty , 0 )                    this_sch_in_qty     --当月入庫予定数
        ,NVL( STRN.this_sch_out_qty, 0 )                    this_sch_out_qty    --当月出庫予定数
        ,STRN.m_end_qty                                     m_end_qty           --月末在庫数
        ,NVL( STRN.stc_r_cs_qty    , 0 )                    stc_r_cs_qty        --棚卸ケース数
        ,NVL( STRN.stc_r_qty       , 0 )                    stc_r_qty           --棚卸バラ数
        ,NVL( STRN.next_in_qty     , 0 )                    next_in_qty         --翌月入庫数
        ,NVL( STRN.next_out_qty    , 0 )                    next_out_qty        --翌月出庫数
        ,NVL( STRN.loct_onhand     , 0 )                    loct_onhand         --現在庫数
        ,NVL( STRN.sch_in_qty      , 0 )                    sch_in_qty          --入庫予定数
        ,NVL( STRN.sch_out_qty     , 0 )                    sch_out_qty         --出庫予定数
        ,STRN.enable_qty                                    enable_qty          --引当可能数
  FROM  (  --倉庫コード、保管場所コード、品目ID、ロットID単位で集計
           SELECT  TRAN.whse_code                           whse_code           --倉庫コード
                  ,TRAN.location                            location            --保管場所コード
                  ,TRAN.item_id                             item_id             --品目ID
                  ,TRAN.lot_id                              lot_id              --ロットID
                  ,SUM( TRAN.m_start_qty )                  m_start_qty         --月首在庫数
                  ,SUM( TRAN.this_in_qty )                  this_in_qty         --当月入庫数
                  ,SUM( TRAN.this_out_qty )                 this_out_qty        --当月出庫数
                  ,SUM( TRAN.this_sch_in_qty )              this_sch_in_qty     --当月入庫予定数
                  ,SUM( TRAN.this_sch_out_qty )             this_sch_out_qty    --当月出庫予定数
                   --月末在庫数(月首在庫数＋当月入庫数－当月出庫数)
                  ,SUM( NVL( TRAN.m_start_qty, 0 )
                      + NVL( TRAN.this_in_qty, 0 ) - NVL( TRAN.this_out_qty, 0 )
                   )                                        m_end_qty           --月末在庫数
                  ,SUM( TRAN.stc_r_cs_qty )                 stc_r_cs_qty        --棚卸ケース数
                  ,SUM( TRAN.stc_r_qty )                    stc_r_qty           --棚卸バラ数
                  ,SUM( TRAN.next_in_qty )                  next_in_qty         --翌月入庫数
                  ,SUM( TRAN.next_out_qty )                 next_out_qty        --翌月出庫数
                  ,SUM( TRAN.loct_onhand )                  loct_onhand         --現在庫数
                  ,SUM( TRAN.sch_in_qty )                   sch_in_qty          --入庫予定数
                  ,SUM( TRAN.sch_out_qty )                  sch_out_qty         --出庫予定数
                   --引当可能数(現在庫数＋入庫予定数－出庫予定数)
                  ,SUM( NVL( TRAN.loct_onhand, 0 )
                      + NVL( TRAN.sch_in_qty , 0 )
                      - NVL( TRAN.sch_out_qty, 0 )
                   )                                        enable_qty          --引当可能数
             FROM  (
                     --======================================================================
                     -- 棚卸結果アドオンから棚卸在庫数を取得
                     --======================================================================
                      SELECT
                              XSIR.invent_whse_code         whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,XSIR.item_id                  item_id             --品目ID
                             ,NVL( XSIR.lot_id, 0 )         lot_id              --ロットID（NULLはDEFAULTLOT）
                             ,TRUNC( NVL( XSIR.case_amt, 0 ) + ( NVL( XSIR.loose_amt, 0 ) / DECODE( XSIR.content, NULL, 1, 0, 1, XSIR.content ) ) )
                                                            stc_r_cs_qty        --棚卸ケース数 (棚卸結果アドオンテーブルのみケース数とバラ数の和で総数となっている)
                             ,( NVL( XSIR.case_amt, 0 ) * NVL( XSIR.content, 0 ) ) + NVL( XSIR.loose_amt, 0 )
                                                            stc_r_qty           --棚卸バラ数   (棚卸結果アドオンテーブルのみケース数とバラ数の和で総数となっている)
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM
                              xxinv_stc_inventory_result    XSIR                --棚卸結果アドオン
                             ,xxskz_item_locations_v        XILV                --保管場所取得用
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                            ( XSIR.case_amt <> 0  OR  XSIR.loose_amt <> 0 )
                         AND  TO_CHAR( XSIR.invent_date, 'YYYYMM' ) = TO_CHAR( PRD.this_last_day, 'YYYYMM' )  --当月データを対象とする
                         AND  XSIR.invent_whse_code         = XILV.whse_code
                         AND  XILV.allow_pickup_flag        = '1'               --出荷引当対象フラグ
                     --<< 棚卸結果アドオンから棚卸在庫数を取得 END >>--
                    UNION ALL
                    --=====================================================================================
                    -- ロット別月次在庫テーブルから月首在庫数(直近のクローズ会計期間データ)を取得
                    --=====================================================================================
                      SELECT  IPB.whse_code                 whse_code           --倉庫コード
                             ,IPB.location                  location            --保管場所コード
                             ,IPB.item_id                   item_id             --品目ID
                             ,IPB.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,IPB.loct_onhand               m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  ic_perd_bal                   IPB                 --ロット別月次在庫
                             ,ic_cldr_dtl                   ICD1                --在庫カレンダ
                             ,(  --直近のクローズ在庫会計期間を取得
                                 SELECT  MAX( ICD2.period_end_date )  period_end_date
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                              --直近のクローズ在庫会計期間でのデータ検索
                              ICD1.orgn_code                = 'ITOE'
                         AND  ICD1.period_end_date          = PRD.period_end_date
                         AND  IPB.period_id                 = ICD1.period_id
                    --<< 月首在庫数 END >>--
                    UNION ALL
                    --======================================================================
                    -- 当月・翌月の入出庫数(実績)を取得    ※当月 = クローズ会計期間の次月
                    --   １．OPM完了トランザクション
                    --   ２．OPM保留トランザクション
                    --
                    -- 【以下は標準トランザクションに未反映の実績データ  ※現在庫にも反映】
                    --   ３．移動入庫実績(出庫報告待ち)
                    --   ４．移動出庫実績(入庫報告待ち)
                    --   ５．移動入庫実績(実績訂正)
                    --   ６．移動出庫実績(実績訂正)
                    --   ７．出荷・倉替返品実績(EBS実績計上待ち)
                    --   ８．支給実績(EBS実績計上待ち)
                    --======================================================================
                      -------------------------------------------------------------
                      -- １．OPM完了トランザクション
                      -------------------------------------------------------------
                      -- ①『移動(積送無し)』『相手先在庫』『移動実績訂正』は入庫or出庫判定を取引数で行なう
                      SELECT  ITC.whse_code                 whse_code           --倉庫コード
                             ,ITC.location                  location            --保管場所コード
                             ,ITC.item_id                   item_id             --品目ID
                             ,ITC.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN ITC.trans_qty > 0 THEN                            --取引数が正の値
                                  ITC.trans_qty
                              END END                       this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN ITC.trans_qty < 0 THEN                            --取引数が負の値
                                  ABS( ITC.trans_qty )
                              END END                       this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN ITC.trans_qty > 0 THEN                            --取引数が正の値
                                  ITC.trans_qty
                              END END                       next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN ITC.trans_qty < 0 THEN                            --取引数が負の値
                                  ABS( ITC.trans_qty )
                              END END                       next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_ic_tran_cmp_arc                   ITC     --OPM完了在庫トランザクション（標準）バックアップ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                              (   ITC.doc_type             <> 'ADJI'            --在庫調整以外
                               OR ITC.reason_code           = 'X977'            --相手先在庫
                               OR ITC.reason_code           = 'X123'            --移動実績訂正
                              )
                         AND  ITC.trans_qty                <> 0
                         AND  TRUNC( ITC.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --当月首以降のデータ
                    UNION ALL
                      -- ②『相手先在庫』『移動実績訂正』以外の在庫調整データは入庫or出庫判定を受払区分マスタで行なう
                      --   ⇒【理由】『仕入先返品』はマイナス値の入庫扱い等、マイナス値のケースが存在する
                      SELECT  ITC.whse_code                 whse_code           --倉庫コード
                             ,ITC.location                  location            --保管場所コード
                             ,ITC.item_id                   item_id             --品目ID
                             ,ITC.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN XRPM.rcv_pay_div = '1' THEN           --受入
                                  ITC.trans_qty
                              END END                       this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN XRPM.rcv_pay_div = '-1' THEN          --払出
                                  ITC.trans_qty * -1
                              END END                       this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN XRPM.rcv_pay_div = '1' THEN           --受入
                                  ITC.trans_qty
                              END END                       next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( ITC.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN XRPM.rcv_pay_div = '-1' THEN          --払出
                                  ITC.trans_qty * -1
                              END END                       next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_rcv_pay_mst             XRPM                --受払区分アドオンマスタ
                             ,ic_adjs_jnl                   IAJ                 --OPM在庫調整ジャーナル
                             ,ic_jrnl_mst                   IJM                 --OPMジャーナルマスタ
                             ,xxcmn_ic_tran_cmp_arc                   ITC                 --OPM完了在庫トランザクション（標準）バックアップ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         -- 受払区分アドオンマスタの条件
                              XRPM.doc_type                 = 'ADJI'            --在庫調整
                         AND  XRPM.reason_code              <> 'X977'           --相手先在庫 以外
                         AND  XRPM.reason_code              <> 'X123'           --移動実績訂正 以外
                         AND  XRPM.use_div_invent           = 'Y'
                         -- OPM完了在庫トランザクションとの結合
                         AND  ITC.trans_qty                 <> 0
                         AND  ITC.doc_type                  = XRPM.doc_type
                         AND  ITC.reason_code               = XRPM.reason_code
                         AND  TRUNC( ITC.trans_date )       >= TRUNC( PRD.this_last_day, 'MONTH' )  --当月首以降のデータ
                         -- OPM在庫調整ジャーナルとの結合
                         AND  ITC.doc_type                  = IAJ.trans_type
                         AND  ITC.doc_id                    = IAJ.doc_id
                         AND  ITC.doc_line                  = IAJ.doc_line
                         -- OPMジャーナルマスタとの結合
                         AND  IAJ.journal_id                = IJM.journal_id
                      --[ １．OPM完了トランザクション  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ２．OPM保留トランザクション
                      -------------------------------------------------------------
                      -- ①『移動関連』『生産関連』は入庫or出庫判定を取引数で行なう
                      SELECT  ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN ITP.trans_qty > 0 THEN                            --取引数が正の値
                                  ITP.trans_qty
                              END END                       this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN ITP.trans_qty < 0 THEN                            --取引数が負の値
                                  ABS( ITP.trans_qty )
                              END END                       this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN ITP.trans_qty > 0 THEN                            --取引数が正の値
                                  ITP.trans_qty
                              END END                       next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN ITP.trans_qty < 0 THEN                            --取引数が負の値
                                  ABS( ITP.trans_qty )
                              END END                       next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_ic_tran_pnd_arc                   ITP       --OPM保留在庫トランザクション（標準）バックアップ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  (   ITP.doc_type              = 'XFER'            --移動関連
                               OR ITP.doc_type              = 'PROD'            --生産関連
                              )
                         AND  ITP.completed_ind             = '1'               --完了(実績として手持ち在庫に反映済)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --当月首以降のデータ
                    UNION ALL
                      -- ②『受注関連』は入庫or出庫判定を受注タイプ区分で行なう
                      --   ⇒【理由】『倉替返品取消』はマイナス値の入庫扱い
                      SELECT  ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --『倉替返品取消』の場合
                                  ITP.trans_qty                                             --マイナス値の入庫
                              END END                       this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --『出荷･支給』の場合
                                  ITP.trans_qty * -1
                              END END                       this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --『倉替返品取消』の場合
                                  ITP.trans_qty                                             --マイナス値の入庫
                              END END                       next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --『出荷･支給』の場合
                                  ITP.trans_qty * -1
                              END END                       next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_ic_tran_pnd_arc                   ITP       --OPM保留在庫トランザクション（標準）バックアップ
                             ,wsh_delivery_details          WDD                 --出荷搬送明細
                             ,xxcmn_oe_order_headers_all_arc          OHA       --受注ヘッダ（標準）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  ITP.doc_type                  = 'OMSO'            --受注関連
                         AND  ITP.completed_ind             = '1'               --完了(実績として手持ち在庫に反映済)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --当月首以降のデータ
                         --出荷搬送明細データの取得
                         AND  ITP.line_detail_id            = WDD.delivery_detail_id
                         --受注ヘッダデータの取得
                         AND  WDD.source_header_id          = OHA.header_id
                         AND  WDD.org_id                    = OHA.org_id
                         --受注タイプデータの取得
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                    UNION ALL
                      -- ③『購買関連（仕入実績）』は全て入庫扱いで行なう
                      SELECT  ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                ITP.trans_qty
                              END                           this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                ITP.trans_qty
                              END                           next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  ic_tran_pnd                   ITP                 --OPM保留トランザクション
                             ,rcv_shipment_lines                      RSL                 --受入明細
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  ITP.doc_type                  = 'PORC'            --購買関連
                         AND  ITP.completed_ind             = '1'               --完了(実績として手持ち在庫に反映済)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --当月首以降のデータ
                         --受入明細データの取得
                         AND  RSL.source_document_code = 'PO'                   --仕入
                         AND  RSL.shipment_header_id = ITP.doc_id
                         AND  RSL.line_num = ITP.doc_line
                    UNION ALL
                      -- ④『購買関連（受注）』は入庫or出庫判定を受注タイプ区分で行なう
                      --   ⇒【理由】『仕入先返品』はマイナス値の出庫扱い
                      SELECT  ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --『倉替返品』の場合
                                  ITP.trans_qty
                              END END                       this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --『支給先返品』の場合
                                  ITP.trans_qty * -1                                        --マイナス値の出庫
                              END END                       this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN OTTA.attribute1  = '3' THEN                       --『倉替返品』の場合
                                  ITP.trans_qty
                              END END                       next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( ITP.trans_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN OTTA.attribute1 <> '3' THEN                       --『支給先返品』の場合
                                  ITP.trans_qty * -1                                        --マイナス値の出庫
                              END END                       next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_ic_tran_pnd_arc                   ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                             ,xxcmn_rcv_shipment_lines_arc            RSL                 --受入明細（標準）バックアップ
                             ,xxcmn_oe_order_headers_all_arc          OHA                 --受注ヘッダ（標準）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  ITP.doc_type                  = 'PORC'            --購買関連
                         AND  ITP.completed_ind             = '1'               --完了(実績として手持ち在庫に反映済)
                         AND  ITP.trans_qty                <> 0
                         AND  TRUNC( ITP.trans_date )      >= TRUNC( PRD.this_last_day, 'MONTH' )  --当月首以降のデータ
                         --受入明細データの取得
                         AND  RSL.source_document_code = 'RMA'                  --受注
                         AND  RSL.shipment_header_id = ITP.doc_id
                         AND  RSL.line_num = ITP.doc_line
                         --受注ヘッダデータの取得
                         AND  RSL.oe_order_header_id        = OHA.header_id
                         --受注タイプデータの取得
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                      --[ ２．OPM保留トランザクション  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ３．移動入庫実績(出庫報告待ち)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) <= PRD.this_last_day THEN   --当月末以内
                                MLD.actual_quantity
                              END                           this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                MLD.actual_quantity
                              END                           next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                              --現在庫数
                             ,MLD.actual_quantity           loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH               --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上 ⇒ EBS在庫未反映
                         AND  MRIH.status                   IN ( '05', '06' )   --05:入庫報告有、06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '30'              --入庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ ３．移動入庫実績(入出庫報告待ち)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ４．移動出庫実績(入庫報告待ち)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) <= PRD.this_last_day THEN   --当月末以内
                                MLD.actual_quantity
                              END                           this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                MLD.actual_quantity
                              END                           next_out_qty        --翌月出庫数
                              --現在庫数
                             ,MLD.actual_quantity * -1      loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上 ⇒ EBS在庫未反映
                         AND  MRIH.status                   IN ( '04', '06' )   --04:出庫報告有、06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --出庫元保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ ４．移動出庫実績(入出庫報告待ち)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ５．移動入庫実績(実績訂正)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) <= PRD.this_last_day THEN   --当月末以内
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( MRIH.actual_arrival_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                              --現在庫数
                             ,NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                                                            loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  MRIH.comp_actual_flg          = 'Y'               --実績計上 ⇒ EBS在庫反映済
                         AND  MRIH.correct_actual_flg       = 'Y'               --実績訂正済
                         AND  MRIH.status                   = '06'              --06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '30'              --入庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ ５．移動入庫実績(実績訂正)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ６．移動出庫実績(実績訂正)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) <= PRD.this_last_day THEN   --当月末以内
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( MRIH.actual_ship_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 )
                              END                           next_out_qty        --翌月出庫数
                              --現在庫数
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) ) * -1
                                                            loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  MRIH.comp_actual_flg          = 'Y'               --実績計上 ⇒ EBS在庫未反映済
                         AND  MRIH.correct_actual_flg       = 'Y'               --実績訂正済
                         AND  MRIH.status                   = '06'              --06:入出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ ６．移動出庫実績(実績訂正)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ７．出荷・倉替返品実績(EBS実績計上待ち)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                              --当月入庫数
                             ,CASE WHEN TRUNC( OHA.shipped_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN OTTA.attribute1 = '3' THEN                          --『倉替返品』の場合
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 )
                              END END                       this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( OHA.shipped_date ) <= PRD.this_last_day THEN   --当月末以内
                                CASE WHEN OTTA.attribute1 = '1' THEN                          --『出荷』の場合
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END END                       this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                              --翌月入庫数
                             ,CASE WHEN TRUNC( OHA.shipped_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN OTTA.attribute1 = '3' THEN                          --『倉替返品』の場合
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'ORDER', -1, 1 )
                              END END                       next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( OHA.shipped_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                CASE WHEN OTTA.attribute1 = '1' THEN                          --『出荷』の場合
                                  ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                     * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END END                       next_out_qty        --翌月出庫数
                              --現在庫数
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  OHA.req_status                = '04'              --実績計上済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上 ⇒ EBS在庫未反映
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               IN ( '1', '3' )     --出荷依頼、倉替返品
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '10'              --出荷依頼
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ ７．出荷・倉替返品実績(着荷報告待ち)  End ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ８．支給実績(EBS実績計上待ち)
                      -------------------------------------------------------------
                      SELECT  XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                              --当月出庫数
                             ,CASE WHEN TRUNC( OHA.shipped_date ) <= PRD.this_last_day THEN   --当月末以内
                                   ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                      * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                              --翌月出庫数
                             ,CASE WHEN TRUNC( OHA.shipped_date ) >  PRD.this_last_day THEN   --翌月以上(当月末より後)
                                   ( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                      * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           next_out_qty        --翌月出庫数
                              --現在庫数
                             ,( NVL( MLD.actual_quantity, 0 ) - NVL( MLD.before_actual_quantity, 0 ) )
                                * DECODE( OTTA.order_category_code, 'RETURN', 1, -1 )
                                                            loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE  OHA.req_status                = '08'              --実績計上済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上 ⇒ EBS在庫未反映
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               = '2'               --支給指示
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '30'              --支給指示
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ ８．支給実績(着荷報告待ち)  End ]--
                    --<< 当月・翌月の入出庫数(実績)を取得  END >>--
                    UNION ALL
                    --======================================================================
                    -- 手持ち在庫から現在庫数を取得
                    --======================================================================
                      SELECT  ILI.whse_code                 whse_code           --倉庫コード
                             ,ILI.location                  location            --保管場所コード
                             ,ILI.item_id                   item_id             --品目ID
                             ,ILI.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,ILI.loct_onhand               loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM  ic_loct_inv                   ILI                 --OPM手持ち数量
                    --<< 手持ち在庫から現在庫数を取得  END >>--
--
                    UNION ALL
                    --======================================================================
                    -- 当月首以降の入庫予定数を各トランザクションから取得
                    --  １．発注受入予定
                    --  ２．移動入庫予定(指示 積送あり＆積送なし)
                    --  ３．移動入庫予定(出庫報告有 積送あり)
                    --  ４．生産入庫予定(完成品[半製品]、副産物)
                    --  ５．生産入庫予定 品目振替 品種振替
                    --======================================================================
                    --======================================================================
                      -------------------------------------------------------------
                      -- １．発注受入予定
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,IIMB.item_id                  item_id             --品目ID
                             ,NVL( ILM.lot_id, 0 )          lot_id              --ロットID (NULLでは集計されない為NVL使用)
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,CASE WHEN TO_DATE( PHA.attribute4, 'YYYY/MM/DD' ) <= PRD.this_last_day THEN   --当月末以内
                                PLA.quantity
                              END                           this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,PLA.quantity                  sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM
                              po_headers_all                PHA                 --発注ヘッダ
                             ,po_lines_all                  PLA                 --発注明細
                             ,xxskz_item_locations_v        XILV                --保管場所マスタ(倉庫コード取得用)
                             ,ic_item_mst_b                 IIMB                --OPM品目マスタ(OPM品目ID取得用)
                             ,mtl_system_items_b            MSIB                --INV品目マスタ(OPM品目ID取得用)
                             ,ic_lots_mst                   ILM                 --OPMロットマスタ(ロットID取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --発注ヘッダの条件
                              PHA.attribute1                IN ( '20', '25' )   --20:発注作成済、25:受入あり
                         --発注明細との結合
                         AND  NVL( PLA.attribute13, 'N' )  <> 'Y'               --未承諾
                         AND  NVL( PLA.cancel_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  PHA.po_header_id              = PLA.po_header_id
                         --倉庫コード取得
                         AND  PHA.attribute5                = XILV.segment1
                         --OPM品目ID取得
                         AND  PLA.item_id                   = MSIB.inventory_item_id
                         AND  MSIB.organization_id          = FND_PROFILE.VALUE('XXCMN_MASTER_ORG_ID')
                         AND  MSIB.segment1                 = IIMB.item_no
                         --OPMロットID取得
                         AND  IIMB.item_id                  = ILM.item_id
                         AND (   ( IIMB.lot_ctl = 1 AND PLA.attribute1 = ILM.lot_no )  --ロット管理品
                              OR ( IIMB.lot_ctl = 0 AND ILM.lot_id     = 0          )  --非ロット管理品
                             )
                         --入庫先保管場所情報取得
                         AND  PHA.attribute5 = XILV.segment1
                      --[ １．発注受入予定  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ２．移動入庫予定(指示 積送あり＆積送なし)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,CASE WHEN MRIH.schedule_arrival_date <= PRD.this_last_day THEN   --当月末以内
                                MLD.actual_quantity
                              END                           this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,MLD.actual_quantity           sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   IN ( '02', '03' )   --02:依頼済、03:調整中
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'           --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ ２．移動入庫予定(指示 積送あり＆積送なし)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ３．移動入庫予定(出庫報告有 積送あり)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,CASE WHEN MRIH.schedule_arrival_date <= PRD.this_last_day THEN   --当月末以内
                                MLD.actual_quantity
                              END                           this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,MLD.actual_quantity           sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.mov_type                 = '1'               --積送あり
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   = '04'              --04:出庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '20'              --出庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --入庫先保管場所情報取得
                         AND  MRIH.ship_to_locat_id         = XILV.inventory_location_id
                      --[ ３．移動入庫予定(出庫報告有 積送あり)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ４．生産入庫予定(完成品[半製品]、副産物)
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --当月末以内
                                GMD.plan_qty
                              END                           this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,GMD.plan_qty                  sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                GRB                 --工順マスタ
                             ,xxcmn_gme_material_details_arc          GMD                 --生産原料詳細（標準）バックアップ
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --生産バッチの条件
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:保留、2:WIP
                         --工順マスタとの結合
                         AND  GRB.routing_class             NOT IN ( '61', '62', '70' )  -- 品目振替(70)、解体(61,62) 以外
                         AND  GBH.routing_id                = GRB.routing_id
                         --生産原料詳細との結合(完成品、副産物のみ)
                         AND  GMD.line_type                 IN ( '1', '2' )     --1:完成品、2:副産物
                         AND  GBH.batch_id                  = GMD.batch_id
                         --保留在庫トランザクション
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- 完了していない(⇒予定)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                         AND  ITP.location                  = GRB.attribute9
                      --[ ４．生産入庫予定(完成品[半製品]、副産物)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      --  ５．生産入庫予定 品目振替 品種振替
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --当月末以内
                                GMD.plan_qty
                              END                           this_sch_in_qty     --当月入庫予定数
                             ,0                             this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,GMD.plan_qty                  sch_in_qty          --入庫予定数
                             ,0                             sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                GRB                 --工順マスタ
                             ,xxcmn_gme_material_details_arc          GMD                 --生産原料詳細（標準）バックアップ
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --生産バッチの条件
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:保留、2:WIP
                         --工順マスタとの結合
                         AND  GRB.routing_class             = '70'              -- 品目振替
                         AND  GBH.routing_id                = GRB.routing_id
                         --生産原料詳細との結合(完成品、副産物のみ)
                         AND  GMD.line_type                 = 1                 -- 振替先
                         AND  GBH.batch_id                  = GMD.batch_id
                         --保留在庫トランザクション
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- 完了していない(⇒予定)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.lot_id                   <> 0                 --『資材』は有り得ない
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                      --[ ５．生産入庫予定 品目振替 品種振替  END ]--
                     -- << 入庫予定数を各トランザクションから取得  END >>
                    UNION ALL
                     --======================================================================
                     -- 出庫予定数を各トランザクションから取得
                     --  １．移動出庫予定(指示 積送あり＆積送なし)
                     --  ２．移動出庫予定(入庫報告有 積送あり)
                     --  ３．受注出荷予定
                     --  ４．有償出荷予定
                     --  ５．生産原料投入予定
                     --  ６．生産出庫予定 品目振替 品種振替
                     --  ７．相手先在庫出庫予定
                     --======================================================================
                      -------------------------------------------------------------
                      -- １．移動出庫予定(指示 積送あり＆積送なし)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,CASE WHEN MRIH.schedule_ship_date <= PRD.this_last_day THEN   --当月末以内
                                MLD.actual_quantity
                              END                           this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,MLD.actual_quantity           sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   IN ( '02', '03' )   --02:依頼済、03:調整中
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --出庫元保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ １．移動出庫予定(指示 積送あり＆積送なし)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ２．移動出庫予定(入庫報告有 積送あり)
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,CASE WHEN MRIH.schedule_ship_date <= PRD.this_last_day THEN   --当月末以内
                                MLD.actual_quantity
                              END                           this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,MLD.actual_quantity           sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_mov_req_instr_hdrs_arc   MRIH                --移動依頼/指示ヘッダ（アドオン）バックアップ
                             ,xxcmn_mov_req_instr_lines_arc     MRIL                --移動依頼/指示明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --移動依頼/指示ヘッダの条件
                              MRIH.mov_type                 = '1'               --積送あり
                         AND  NVL( MRIH.comp_actual_flg, 'N' ) <> 'Y'           --実績未計上
                         AND  MRIH.status                   = '05'              --05:入庫報告有
                         --移動依頼/指示明細との結合
                         AND  NVL( MRIL.delete_flg, 'N' )  <> 'Y'               --無効ではない
                         AND  MRIH.mov_hdr_id               = MRIL.mov_hdr_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '20'              --移動
                         AND  MLD.record_type_code          = '30'              --入庫実績
                         AND  MRIL.mov_line_id              = MLD.mov_line_id
                         --出庫元保管場所情報取得
                         AND  MRIH.shipped_locat_id         = XILV.inventory_location_id
                      --[ ２．移動出庫予定(入庫報告有 積送あり)  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ３．受注出荷予定
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                              --当月出庫予定数
                             ,CASE WHEN OHA.schedule_ship_date <= PRD.this_last_day THEN   --当月末以内
                                   MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                              --出庫予定数
                             ,MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                            sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --受注ヘッダの条件
                              OHA.req_status                = '03'              --締め済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               = '1'               --出荷依頼
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '10'              --出荷依頼
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ ３．受注出荷予定  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ４．有償出荷予定
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                              --当月出庫予定数
                             ,CASE WHEN OHA.schedule_ship_date <= PRD.this_last_day THEN   --当月末以内
                                   MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                              END                           this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                              --出庫予定数
                             ,MLD.actual_quantity * DECODE( OTTA.order_category_code, 'RETURN', -1, 1 )
                                                            sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_order_headers_all_arc       OHA                 --受注ヘッダ（アドオン）バックアップ
                             ,xxcmn_order_lines_all_arc         OLA                 --受注明細（アドオン）バックアップ
                             ,xxcmn_mov_lot_details_arc         MLD                 --移動ロット詳細（アドオン）バックアップ
                             ,oe_transaction_types_all      OTTA                --受注タイプ
                             ,xxskz_item_locations2_v       XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --受注ヘッダの条件
                              OHA.req_status                = '07'              --受領済
                         AND  NVL( OHA.actual_confirm_class, 'N' ) = 'N'        --実績未計上
                         AND  NVL( OHA.latest_external_flag, 'N' ) = 'Y'        --ON
                         --受注タイプマスタとの結合(出荷データを抽出)
                         AND  OTTA.attribute1               = '2'               --支給指示
                         AND  OHA.order_type_id             = OTTA.transaction_type_id
                         --受注明細との結合
                         AND  NVL( OLA.delete_flag, 'N' )  <> 'Y'               --無効明細以外
                         AND  OHA.order_header_id           = OLA.order_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '30'              --支給指示
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  MLD.mov_line_id               = OLA.order_line_id
                         --出庫元保管場所情報取得
                         AND  OHA.deliver_from_id           = XILV.inventory_location_id
                      --[ ４．有償出荷予定  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ５．生産原料投入予定
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --当月末以内
                                ITP.trans_qty * -1
                              END                           this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,ITP.trans_qty * -1            sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                GRB                 --工順マスタ
                             ,xxcmn_gme_material_details_arc          GMD                 --生産原料詳細（標準）バックアップ
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --生産バッチの条件
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:保留、2:WIP
                         --工順マスタとの結合
                         AND  GBH.routing_id                = GRB.routing_id
                         AND  GRB.routing_class             NOT IN ( '61', '62', '70' )  -- 品目振替(70)、解体(61,62) 以外
                         --生産原料詳細との結合(原料のみ)
                         AND  GMD.line_type                 = -1                -- -1:原料
                         AND  GBH.batch_id                  = GMD.batch_id
                         --保留在庫トランザクション
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- 完了していない(⇒予定)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                         AND  ITP.location                  = GRB.attribute9
                      --[ ５．生産原料投入予定  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      --  ６．生産出庫予定 品目振替 品種振替
                      -------------------------------------------------------------
                      SELECT
                              ITP.whse_code                 whse_code           --倉庫コード
                             ,ITP.location                  location            --保管場所コード
                             ,ITP.item_id                   item_id             --品目ID
                             ,ITP.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,CASE WHEN GBH.plan_start_date <= PRD.this_last_day THEN   --当月末以内
                                GMD.plan_qty
                              END                           this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,GMD.plan_qty                  sch_out_qty         --出庫予定数
                        FROM
                              xxcmn_gme_batch_header_arc              GBH       --生産バッチヘッダ（標準）バックアップ
                             ,gmd_routings_b                GRB                 --工順マスタ
                             ,xxcmn_gme_material_details_arc          GMD                 --生産原料詳細（標準）バックアップ
                             ,xxcmn_ic_tran_pnd_arc                   ITP                 --OPM保留在庫トランザクション（標準）バックアップ
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --生産バッチの条件
                              GBH.batch_type                = 0
                         AND  GBH.batch_status              IN ( '1', '2' )     -- 1:保留、2:WIP
                         --工順マスタとの結合
                         AND  GRB.routing_class             = '70'              -- 品目振替
                         AND  GBH.routing_id                = GRB.routing_id
                         --生産原料詳細との結合(完成品、副産物のみ)
                         AND  GMD.line_type                 = -1                -- 振替元
                         AND  GBH.batch_id                  = GMD.batch_id
                         --保留在庫トランザクション
                         AND  ITP.doc_type                  = 'PROD'
                         AND  ITP.delete_mark               = 0
                         AND  ITP.completed_ind             = 0                 -- 完了していない(⇒予定)
                         AND  ITP.reverse_id                IS NULL
                         AND  ITP.lot_id                   <> 0                 --『資材』は有り得ない
                         AND  ITP.line_id                   = GMD.material_detail_id
                         AND  ITP.item_id                   = GMD.item_id
                      --[ ６．生産出庫予定 品目振替 品種振替  END ]--
                    UNION ALL
                      -------------------------------------------------------------
                      -- ７．相手先在庫出庫予定
                      -------------------------------------------------------------
                      SELECT
                              XILV.whse_code                whse_code           --倉庫コード
                             ,XILV.segment1                 location            --保管場所コード
                             ,MLD.item_id                   item_id             --品目ID
                             ,MLD.lot_id                    lot_id              --ロットID
                             ,0                             stc_r_cs_qty        --棚卸ケース数
                             ,0                             stc_r_qty           --棚卸バラ数
                             ,0                             m_start_qty         --月首在庫数
                             ,0                             this_in_qty         --当月入庫数
                             ,0                             this_out_qty        --当月出庫数
                             ,0                             this_sch_in_qty     --当月入庫予定数
                             ,CASE WHEN TO_DATE( PHA.attribute4, 'YYYY/MM/DD' ) <= PRD.this_last_day THEN   --当月末以内
                                PLA.quantity
                              END                           this_sch_out_qty    --当月出庫予定数
                             ,0                             next_in_qty         --翌月入庫数
                             ,0                             next_out_qty        --翌月出庫数
                             ,0                             loct_onhand         --現在庫数
                             ,0                             sch_in_qty          --入庫予定数
                             ,PLA.quantity                  sch_out_qty         --出庫予定数
                        FROM
                              po_headers_all                PHA                 --発注ヘッダ
                             ,po_lines_all                  PLA                 --発注明細
                             ,xxinv_mov_lot_details         MLD                 --移動ロット詳細
                             ,xxskz_item_locations_v        XILV                --保管場所マスタ(倉庫コード取得用)
                             ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
                                 SELECT  ADD_MONTHS( MAX( ICD2.period_end_date ), 1 )  this_last_day
                                   FROM  ic_cldr_dtl        ICD2
                                  WHERE  ICD2.orgn_code     = 'ITOE'
                                    AND  ICD2.closed_period_ind <> 1            --'3:クローズ'
                              )  PRD
                       WHERE
                         --発注ヘッダの条件
                              PHA.attribute1                IN ( '20', '25' )   --20:発注作成済、25:受入あり
                         AND  PHA.attribute11               = '3'
                         --発注明細との結合
                         AND  NVL( PLA.attribute13, 'N' )  <> 'Y'               --未承諾
                         AND  NVL( PLA.cancel_flag, 'N' )  <> 'Y'
                         AND  PHA.po_header_id              = PLA.po_header_id
                         --移動ロット詳細との結合
                         AND  MLD.document_type_code        = '50'              --発注
                         AND  MLD.record_type_code          = '10'              --指示
                         AND  PLA.po_line_id                = MLD.mov_line_id
                         --倉庫コード取得
                         AND  PLA.attribute12               = XILV.segment1
                      --[ ７．相手先在庫出庫予定  END ]--
                     -- << 出庫予定数を各トランザクションから取得  END >>
                   )  TRAN
           GROUP BY TRAN.whse_code    --倉庫コード
                   ,TRAN.location     --保管場所コード
                   ,TRAN.item_id      --品目ID
                   ,TRAN.lot_id       --ロットID
        )  STRN
       ,(  --直近のクローズ在庫会計期間の次月(当月)の末日を取得
           SELECT  TO_CHAR( ADD_MONTHS( MAX( ICD2.period_end_date ), 1 ), 'YYYYMM' )  yyyymm
             FROM  ic_cldr_dtl  ICD2
            WHERE  ICD2.orgn_code = 'ITOE'
              AND  ICD2.closed_period_ind <> 1        --'3:クローズ'
        )  PRD
       ,ic_whse_mst                IWM     --倉庫マスタ
       ,xxskz_item_locations_v     ILOC    --保管場所取得用
       ,xxskz_item_mst_v           ITEM    --品目名称取得用(SYSDATEで取得)
       ,xxskz_prod_class_v         PRODC   --商品区分取得用
       ,xxskz_item_class_v         ITEMC   --品目区分取得用
       ,xxskz_crowd_code_v         CROWD   --群コード取得用
       ,ic_lots_mst                ILM     --ロットマスタ
       ,fnd_lookup_values          FLV01   --クイックコード(名義)
 WHERE
   --倉庫名取得用
        STRN.whse_code             = IWM.whse_code(+)
   --保管場所取得
   AND  STRN.location              = ILOC.segment1(+)
   --品目名称取得(SYSDATEで取得)
   AND  STRN.item_id               = ITEM.item_id(+)
   --品目カテゴリ名取得
   AND  STRN.item_id               = PRODC.item_id(+)
   AND  STRN.item_id               = ITEMC.item_id(+)
   AND  STRN.item_id               = CROWD.item_id(+)
   --ロット情報取得
   AND  STRN.item_id               = ILM.item_id(+)
   AND  STRN.lot_id                = ILM.lot_id(+)
   --名義取得
   AND  FLV01.language(+)          = 'JA'                --言語
   AND  FLV01.lookup_type(+)       = 'XXCMN_INV_CTRL'    --クイックコードタイプ
   AND  FLV01.lookup_code(+)       = IWM.attribute1      --クイックコード
/
COMMENT ON TABLE APPS.XXSKZ_在庫情報_基本_V IS 'SKYLINK用 在庫情報（基本）VIEW'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.当月           IS '当月'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.名義コード     IS '名義コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.名義           IS '名義'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.倉庫コード     IS '倉庫コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.倉庫名         IS '倉庫名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.保管場所コード IS '保管場所コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.保管場所名     IS '保管場所名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.保管場所略称   IS '保管場所略称'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.商品区分       IS '商品区分'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.商品区分名     IS '商品区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.品目区分       IS '品目区分'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.品目区分名     IS '品目区分名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.群コード       IS '群コード'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.品目           IS '品目'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.品目名         IS '品目名'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.品目略称       IS '品目略称'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.ロットNO       IS 'ロットNo'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.製造年月日     IS '製造年月日'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.固有記号       IS '固有記号'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.賞味期限       IS '賞味期限'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.月首在庫数     IS '月首在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.当月入庫数     IS '当月入庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.当月出庫数     IS '当月出庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.当月入庫予定数 IS '当月入庫予定数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.当月出庫予定数 IS '当月出庫予定数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.月末在庫数     IS '月末在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.棚卸ケース数   IS '棚卸ケース数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.棚卸バラ数     IS '棚卸バラ数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.翌月入庫数     IS '翌月入庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.翌月出庫数     IS '翌月出庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.現在庫数       IS '現在庫数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.入庫予定数     IS '入庫予定数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.出庫予定数     IS '出庫予定数'
/
COMMENT ON COLUMN APPS.XXSKZ_在庫情報_基本_V.引当可能数     IS '引数可能数'
/
