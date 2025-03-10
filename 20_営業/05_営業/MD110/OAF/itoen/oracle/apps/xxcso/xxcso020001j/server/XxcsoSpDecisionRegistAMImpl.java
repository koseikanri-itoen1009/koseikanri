/*============================================================================
* ファイル名 : XxcsoSpDecisionRegistAMImpl
* 概要説明   : SP専決登録画面アプリケーション・モジュールクラス
* バージョン : 1.25
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-16 1.0  SCS小川浩     新規作成
* 2009-03-04 1.1  SCS小川浩     課題一覧No.73対応
* 2009-03-23 1.2  SCS柳平直人   [ST障害T1_0163]課題No.115取り込み
* 2009-04-14 1.3  SCS柳平直人   [ST障害T1_0225]契約先validate修正
* 2009-04-27 1.4  SCS柳平直人   [ST障害T1_0294]売価別条件確定事項反映修正
* 2009-08-04 1.5  SCS小川浩     [SCS障害0000908]コピー時の回送先再設定対応
* 2009-08-24 1.6  SCS阿部大輔   [SCS障害0001104]申請区分チェック対応
* 2009-10-14 1.7  SCS阿部大輔   [共通課題IE554,IE573]住所対応
* 2009-11-29 1.8  SCS阿部大輔   [E_本稼動_00106]アカウント複数対応
* 2010-01-08 1.9  SCS阿部大輔   [E_本稼動_01031]取引条件チェック対応
* 2010-01-15 1.10 SCS阿部大輔   [E_本稼動_00950]画面値、ＤＢ値チェック対応
* 2010-03-01 1.11 SCS阿部大輔   [E_本稼動_01678]現金支払対応
* 2010-11-11 1.12 SCS桐生和幸   [E_本稼動_01954]変動電気代のみの顧客対応
* 2013-04-19 1.13 SCSK桐生和幸  [E_本稼動_09603]契約書未確定による顧客区分遷移の変更対応
* 2014-01-31 1.14 SCSK桐生和幸  [E_本稼動_11397]売価1円対応
* 2014-12-15 1.15 SCSK桐生和幸  [E_本稼動_12565]SP・契約書画面改修対応
* 2016-01-08 1.16 SCSK山下翔太  [E_本稼動_13456]自販機管理システム代替対応
* 2018-05-16 1.17 SCSK小路恭弘  [E_本稼動_14989]ＳＰ項目追加
* 2020-06-16 1.18 SCSK佐々木大和[E_本稼動_15904]税抜きでの自販機BM計算について
* 2020-10-28 1.19 SCSK佐々木大和[E_本稼動_16293]SP・契約書画面からの仕入先コードの選択について
* 2020-11-05 1.20 SCSK佐々木大和[E_本稼動_15904]追加対応第3弾 定価換算率計算式修正
* 2020-11-17 1.21 SCSK佐々木大和[E_本稼動_15904]追加対応第3弾 定価換算率計算式修正 対応不要のため削除
* 2022-04-21 1.22 SCSK二村悠香  [E_本稼動_18060]自販機顧客別利益管理
* 2022-08-03 1.23 SCSK赤地学    [E_本稼動_18060]確認ボタン不具合対応
* 2023-05-18 1.24 SCSK赤地学    [E_本稼動_19238]SP承認チェック不具合対応
* 2024-09-04 1.25 SCSK赤地学    [E_本稼動_20174]自販機顧客支払管理情報の改修
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAApplicationModuleImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.apps.fnd.framework.OAException;
import oracle.jbo.server.ViewLinkImpl;
import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;
import oracle.sql.NUMBER;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.poplist.server.XxcsoLookupListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.poplist.server.XxcsoBusinessCondTypeListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.poplist.server.XxcsoExtRefOpclTypeListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.poplist.server.XxcsoBusinessTypeListVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionInitUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionPropertyUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionReflectUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionValidateUtils;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionCalculateUtils;
import com.sun.java.util.collections.HashMap;
import com.sun.java.util.collections.List;
import com.sun.java.util.collections.ArrayList;
import java.sql.SQLException;
import itoen.oracle.apps.xxcso.xxcso020001j.poplist.server.XxcsoBM1TaxListVOImpl;
import itoen.oracle.apps.xxcso.common.lov.server.XxcsoLookupLovVOImpl;

/*******************************************************************************
 * SP専決書の登録を行うための
 * アプリケーション・モジュールクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionRegistAMImpl extends OAApplicationModuleImpl 
{
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionRegistAMImpl()
  {
  }

// Ver.1.22 Add Start
  /*****************************************************************************
   * 出力メッセージ
   *****************************************************************************
   */
  private OAException mMessage = null;
// Ver.1.22 Add End

  /*****************************************************************************
   * アプリケーション・モジュールの初期化（詳細）処理
   * @param spDecisionHeaderId SP専決ヘッダID
   *****************************************************************************
   */
  public void initDetails(
    String spDecisionHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // トランザクションをクリアする
    rollback();

    // 使用するインスタンスを取得する    
    XxcsoSpDecisionInitVOImpl initVo = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    XxcsoSpDecisionSendInitVOImpl sendInitVo
      = getXxcsoSpDecisionSendInitVO1();
    if ( sendInitVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendInitVO1"
        );
    }
    
    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecRequestFullVO1"
        );
    }

    ///////////////////////////////////////////
    // 本処理
    ///////////////////////////////////////////    
    initVo.executeQuery();
    sendInitVo.executeQuery();
    
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();

    // ヘッダの検索
    headerVo.initQuery(spDecisionHeaderId);

    if ( spDecisionHeaderId == null || "".equals(spDecisionHeaderId) )
    {
      ///////////////////////////////////////
      // トランザクションの初期化
      ///////////////////////////////////////
      XxcsoSpDecisionInitUtils.initializeTransaction(
        txn
       ,null
       ,initRow.getBaseCode()
      );

      // 要求ビューインスタンスの初期化
      requestVo.executeQuery();
      
      ///////////////////////////////////////
      // 新規レコードの初期化
      ///////////////////////////////////////
      XxcsoSpDecisionInitUtils.initializeRow(
        initVo
       ,sendInitVo
       ,headerVo
       ,installVo
       ,cntrctVo
       ,bm1Vo
       ,bm2Vo
       ,bm3Vo
       ,sendVo
      );
    }
    else
    {
      ///////////////////////////////////////
      // トランザクションの初期化
      ///////////////////////////////////////
      XxcsoSpDecisionHeaderFullVORowImpl headerRow
        = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
      
      XxcsoSpDecisionInitUtils.initializeTransaction(
        txn
       ,spDecisionHeaderId
       ,headerRow.getAppBaseCode()
      );      

      // 要求ビューインスタンスの初期化
      requestVo.executeQuery();
    }
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * アプリケーション・モジュールの初期化（コピー）処理
   * @param spDecisionHeaderId SP専決ヘッダID
   *****************************************************************************
   */
  public void initCopyDetails(
    String spDecisionHeaderId
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // トランザクションをクリアする
    rollback();

    // 使用するインスタンスを取得する    
    XxcsoSpDecisionInitVOImpl initVo = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    ///////////////////////////////////////////
    // コピー先用インスタンス
    ///////////////////////////////////////////    
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecRequestFullVO1"
        );
    }

    ///////////////////////////////////////////
    // コピー元用インスタンス
    ///////////////////////////////////////////    
    XxcsoSpDecisionHeaderFullVOImpl headerVo2
      = getXxcsoSpDecisionHeaderFullVO2();
    if ( headerVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO2"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo2
      = getXxcsoSpDecisionInstCustFullVO2();
    if ( installVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO2"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo2
      = getXxcsoSpDecisionCntrctCustFullVO2();
    if ( cntrctVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO2"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo2
      = getXxcsoSpDecisionScLineFullVO2();
    if ( scVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO2"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo2
      = getXxcsoSpDecisionAllCcLineFullVO2();
    if ( allCcVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO2"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo2
      = getXxcsoSpDecisionSelCcLineFullVO2();
    if ( selCcVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO2"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo2
      = getXxcsoSpDecisionBm1CustFullVO2();
    if ( bm1Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO2"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo2
      = getXxcsoSpDecisionBm2CustFullVO2();
    if ( bm2Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO2"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo2
      = getXxcsoSpDecisionBm3CustFullVO2();
    if ( bm3Vo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO2"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo2
      = getXxcsoSpDecisionAttachFullVO2();
    if ( attachVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO2"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo2
      = getXxcsoSpDecisionSendFullVO2();
    if ( sendVo2 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO2"
        );
    }
    
// 2009-08-04 [障害0000908] Add Start
    XxcsoSpDecisionSendInitVOImpl sendInitVo
      = getXxcsoSpDecisionSendInitVO1();
    if ( sendInitVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendInitVO1"
        );
    }
// 2009-08-04 [障害0000908] Add End

    ///////////////////////////////////////////
    // 本処理
    ///////////////////////////////////////////    
    initVo.executeQuery();
    
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();

    // ヘッダの検索
    headerVo.initQuery((String)null);
    headerVo2.initQuery(spDecisionHeaderId);

    ///////////////////////////////////////
    // トランザクションの初期化
    ///////////////////////////////////////
    XxcsoSpDecisionInitUtils.initializeTransaction(
      txn
     ,null
     ,initRow.getBaseCode()
    );

    ///////////////////////////////////////
    // コピー処理
    ///////////////////////////////////////
    XxcsoSpDecisionInitUtils.initializeCopyRow(
      initVo
     ,headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,attachVo
     ,sendVo
     ,headerVo2
     ,installVo2
     ,cntrctVo2
     ,bm1Vo2
     ,bm2Vo2
     ,bm3Vo2
     ,scVo2
     ,allCcVo2
     ,selCcVo2
     ,attachVo2
     ,sendVo2
// 2009-08-04 [障害0000908] Add Start
     ,sendInitVo
// 2009-08-04 [障害0000908] Add End
    );
    
    // 要求ビューインスタンスの初期化
    requestVo.executeQuery();
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 適用ボタン押下処理
   *****************************************************************************
   */
  public HashMap handleApplyButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

// Ver.1.22 Add Start
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
      
    // 設置協賛金、行政財産使用料の支払期間開始年月、支払期間終了年月チェック   
    XxcsoSpDecisionValidateUtils.chkInstallPayAdAssetsPayYearMonth(txn,headerRow,false);
    
    //画面項目 支払期間開始日（設置協賛金）
    Date installPayStartDateScreen 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getInstallPayStartYear(),
                headerRow.getInstallPayStartMonth());

    //画面項目 支払期間終了日（設置協賛金）
    Date installPayEndDateScreen 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getInstallPayEndYear(),
                headerRow.getInstallPayEndMonth());

    //画面項目　支払期間開始日（行政財産使用料）
    Date adAssetsPayStartDateScreen 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getAdAssetsPayStartYear(),
                headerRow.getAdAssetsPayStartMonth());

    //画面項目　支払期間終了日（行政財産使用料）            
    Date adAssetsPayEndDateScreen 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getAdAssetsPayEndYear(),
                headerRow.getAdAssetsPayEndMonth());

    //DB 支払期間開始日（設置協賛金）
    Date installPayStartDate = headerRow.getInstallPayStartDate();
    //DB 支払期間終了日（設置協賛金）
    Date installPayEndDate = headerRow.getInstallPayEndDate();
    //DB 支払期間開始日（行政財産使用料）
    Date adAssetsPayStartDate = headerRow.getAdAssetsPayStartDate();
    //DB 支払期間終了日（行政財産使用料）
    Date adAssetsPayEndDate =  headerRow.getAdAssetsPayEndDate();

    XxcsoUtils.debug(txn, "[installPayStartDateScreen:]" + installPayStartDateScreen);
    XxcsoUtils.debug(txn, "[installPayEndDateScreen:]" + installPayEndDateScreen);
    XxcsoUtils.debug(txn, "[adAssetsPayStartDateScreen:]" + adAssetsPayStartDateScreen);
    XxcsoUtils.debug(txn, "[adAssetsPayEndDateScreen:]" + adAssetsPayEndDateScreen);
    XxcsoUtils.debug(txn, "[installPayStartDate:]" + installPayStartDate);
    XxcsoUtils.debug(txn, "[installPayEndDate:]" + installPayEndDate);
    XxcsoUtils.debug(txn, "[adAssetsPayStartDate:]" + adAssetsPayStartDate);
    XxcsoUtils.debug(txn, "[adAssetsPayEndDate:]" + adAssetsPayEndDate);

    // 支払期間開始日（設置協賛金）が画面項目とDBで異なるかチェック
    if((installPayStartDateScreen != null && installPayStartDate != null 
        && installPayStartDateScreen.compareTo(installPayStartDate) != 0)
        || (installPayStartDateScreen != null && installPayStartDate == null)
        || (installPayStartDateScreen == null && installPayStartDate != null))
    {
       headerRow.setInstallPayStartDate(installPayStartDateScreen);
    }
    
    // 支払期間終了日（設置協賛金）が画面項目とDBで異なるかチェック
    if((installPayEndDateScreen != null && installPayEndDate != null 
        && installPayEndDateScreen.compareTo(installPayEndDate) != 0)
        || (installPayEndDateScreen != null && installPayEndDate == null)
        || (installPayEndDateScreen == null && installPayEndDate != null))
    {
        headerRow.setInstallPayEndDate(installPayEndDateScreen);
    }

    // 支払期間開始日（行政財産使用料）が画面項目とDBで異なるかチェック
    if((adAssetsPayStartDateScreen != null && adAssetsPayStartDate != null 
        && adAssetsPayStartDateScreen.compareTo(adAssetsPayStartDate) != 0)
        || (adAssetsPayStartDateScreen != null && adAssetsPayStartDate == null)
        || (adAssetsPayStartDateScreen == null && adAssetsPayStartDate != null))
    {
        headerRow.setAdAssetsPayStartDate(adAssetsPayStartDateScreen);
    }
    
    // 支払期間終了日（行政財産使用料）が画面項目とDBで異なるかチェック
    if((adAssetsPayEndDateScreen != null && adAssetsPayEndDate != null 
        && adAssetsPayEndDateScreen.compareTo(adAssetsPayEndDate) != 0)
        || (adAssetsPayEndDateScreen != null && adAssetsPayEndDate == null)
        || (adAssetsPayEndDateScreen == null && adAssetsPayEndDate != null))
    {
        headerRow.setAdAssetsPayEndDate(adAssetsPayEndDateScreen);
    }
// Ver.1.22 Add End

    if ( ! getTransaction().isDirty() )
    {
      throw XxcsoMessage.createNotChangedMessage();
    }
// Ver.1.22 Del Start     
//    List errorList = new ArrayList();
    // インスタンス取得
//    XxcsoSpDecisionHeaderFullVOImpl headerVo
//      = getXxcsoSpDecisionHeaderFullVO1();
//    if ( headerVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "getXxcsoSpDecisionHeaderFullVO1"
//        );
//    }
// Ver.1.22 Del End 

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

// Ver.1.22 Del Start    
//    XxcsoSpDecisionHeaderFullVORowImpl headerRow
//      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
// Ver.1.22 Del End

    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    headerRow.setStatus(XxcsoSpDecisionConstants.STATUS_INPUT);
    requestRow.setOperationMode(null);

    validateAll(false);

// Ver.1.22 Add Start
    headerRow.setInstallPayStartDate(installPayStartDateScreen);
    headerRow.setInstallPayEndDate(installPayEndDateScreen);
    headerRow.setAdAssetsPayStartDate(adAssetsPayStartDateScreen);
    headerRow.setAdAssetsPayEndDate(adAssetsPayEndDateScreen);
// Ver.1.22 Add End

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoConstants.TOKEN_VALUE_REGIST
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

// Ver.1.22 Add Start
    /*****************************************************************************
   * 提出ボタン押下処理
   *****************************************************************************
   */
  public void handleSubmitButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // Ver.1.24 Add Start
    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();
    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_SUBMIT);
    // Ver.1.24 Add End
    validateAll(true);
    chkPayStartDate();
    
    XxcsoUtils.debug(txn, "[END]");

  } 
// Ver.1.22 Add End

// Ver.1.22 Del Start
//  /*****************************************************************************
//   * 提出ボタン押下処理
//   *****************************************************************************
//   */
//  public HashMap handleSubmitButton()
//  {
//    OADBTransaction txn = getOADBTransaction();
//
//    XxcsoUtils.debug(txn, "[START]");
//
//    XxcsoSpDecisionHeaderFullVOImpl headerVo
//      = getXxcsoSpDecisionHeaderFullVO1();
//    if ( headerVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "getXxcsoSpDecisionHeaderFullVO1"
//        );
//    }
//
//    XxcsoSpDecRequestFullVOImpl requestVo
//      = getXxcsoSpDecRequestFullVO1();
//    if ( requestVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionHeaderFullVO1"
//        );
//    }
//    
//    XxcsoSpDecisionHeaderFullVORowImpl headerRow
//      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
//    XxcsoSpDecRequestFullVORowImpl requestRow
//      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();
//
//    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_SUBMIT);
//
//    validateAll(true);
//
//    commit();
//
//    OAException msg
//      = XxcsoMessage.createConfirmMessage(
//          XxcsoConstants.APP_XXCSO1_00001
//         ,XxcsoConstants.TOKEN_RECORD
//         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
//            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
//            + headerRow.getSpDecisionNumber()
//            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
//         ,XxcsoConstants.TOKEN_ACTION
//         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SUBMIT
//        );
//
//    HashMap params = new HashMap(2);
//    params.put(
//      XxcsoConstants.EXECUTE_MODE
//     ,XxcsoSpDecisionConstants.DETAIL_MODE
//    );
//    params.put(
//      XxcsoConstants.TRANSACTION_KEY1
//     ,headerRow.getSpDecisionHeaderId()
//    );
//
//    HashMap returnValue = new HashMap(2);
//    returnValue.put(
//      XxcsoSpDecisionConstants.PARAM_URL_PARAM
//     ,params
//    );
//    returnValue.put(
//      XxcsoSpDecisionConstants.PARAM_MESSAGE
//     ,msg
//    );
//    
//    XxcsoUtils.debug(txn, "[END]");
//
//    return returnValue;
//  } 
// Ver.1.22 Del End
  
  /*****************************************************************************
   * 確認ボタン押下処理
   *****************************************************************************
   */
  public HashMap handleConfirmButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_CONFIRM);

    validateAll(true);

// Ver.1.23 Add Start    
    chkPayStartDate();
    
    Date installPayStartDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getInstallPayStartYear(),
                headerRow.getInstallPayStartMonth());
              
    Date installPayEndDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getInstallPayEndYear(),
                headerRow.getInstallPayEndMonth());
              
    Date adAssetsPayStartDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getAdAssetsPayStartYear(),
                headerRow.getAdAssetsPayStartMonth());
              
    Date adAssetsPayEndDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getAdAssetsPayEndYear(),
                headerRow.getAdAssetsPayEndMonth());

    // 支払期間開始日（設置協賛金）
    headerRow.setInstallPayStartDate(installPayStartDate);
    // 支払期間終了日（設置協賛金）
    headerRow.setInstallPayEndDate(installPayEndDate);
    // 支払期間開始日（行政財産使用料）
    headerRow.setAdAssetsPayStartDate(adAssetsPayStartDate);
    // 支払期間終了日（行政財産使用料）
    headerRow.setAdAssetsPayEndDate(adAssetsPayEndDate);
// Ver.1.23 Add End

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_CONFIRM
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
  /*****************************************************************************
   * 返却ボタン押下処理
   *****************************************************************************
   */
  public HashMap handleReturnButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_RETURN);

    validateAll(true);

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_RETURN
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

// Ver.1.22 Add Start
   /*****************************************************************************
   * 承認ボタン押下処理
   *****************************************************************************
   */
  public void handleApproveButton()
  {
    OADBTransaction txn = getOADBTransaction();

    // Ver.1.24 Add Start
    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();
    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_APPROVE);
    // Ver.1.24 Add End
    validateAll(true);
    chkPayStartDate();
    
    XxcsoUtils.debug(txn, "[END]");
  } 
// Ver.1.22 Add End

// Ver.1.22 Del Start
//  /*****************************************************************************
//   * 承認ボタン押下処理
//   *****************************************************************************
//   */
//  public HashMap handleApproveButton()
//  {
//    OADBTransaction txn = getOADBTransaction();
//
//    XxcsoUtils.debug(txn, "[START]");
//
//    XxcsoSpDecisionHeaderFullVOImpl headerVo
//      = getXxcsoSpDecisionHeaderFullVO1();
//    if ( headerVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "getXxcsoSpDecisionHeaderFullVO1"
//        );
//    }
//
//    XxcsoSpDecRequestFullVOImpl requestVo
//      = getXxcsoSpDecRequestFullVO1();
//    if ( requestVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionHeaderFullVO1"
//        );
//    }
//    
//    XxcsoSpDecisionHeaderFullVORowImpl headerRow
//      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
//    XxcsoSpDecRequestFullVORowImpl requestRow
//      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();
//
//    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_APPROVE);
//
//    validateAll(true);
//
//    commit();
//
//    OAException msg
//      = XxcsoMessage.createConfirmMessage(
//          XxcsoConstants.APP_XXCSO1_00001
//         ,XxcsoConstants.TOKEN_RECORD
//         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
//            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
//            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
//            + headerRow.getSpDecisionNumber()
//            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
//         ,XxcsoConstants.TOKEN_ACTION
//         ,XxcsoSpDecisionConstants.TOKEN_VALUE_APPROVE
//        );
//
//    HashMap params = new HashMap(2);
//    params.put(
//      XxcsoConstants.EXECUTE_MODE
//     ,XxcsoSpDecisionConstants.DETAIL_MODE
//    );
//    params.put(
//      XxcsoConstants.TRANSACTION_KEY1
//     ,headerRow.getSpDecisionHeaderId()
//    );
//
//    HashMap returnValue = new HashMap(2);
//    returnValue.put(
//      XxcsoSpDecisionConstants.PARAM_URL_PARAM
//     ,params
//    );
//    returnValue.put(
//      XxcsoSpDecisionConstants.PARAM_MESSAGE
//     ,msg
//    );
//    
//    XxcsoUtils.debug(txn, "[END]");
//
//    return returnValue;
//  }
// Ver.1.22 Del End
  
  /*****************************************************************************
   * 否決ボタン押下処理
   *****************************************************************************
   */
  public HashMap handleRejectButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_REJECT);

    validateAll(true);

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_REJECT
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;
  }

  
// 2016-01-08 [E_本稼動_13456] Del Start
//  /*****************************************************************************
//   * 発注依頼ボタン押下処理
//   *****************************************************************************
//   */
//  public HashMap handleRequestButton()
//  {
//    OADBTransaction txn = getOADBTransaction();
//
//    XxcsoUtils.debug(txn, "[START]");
//
//    XxcsoSpDecisionHeaderFullVOImpl headerVo
//      = getXxcsoSpDecisionHeaderFullVO1();
//    if ( headerVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "getXxcsoSpDecisionHeaderFullVO1"
//        );
//    }
//
//    // 2009-08-24 [障害0001104] Add Start
//    XxcsoSpDecRequestFullVOImpl requestVo
//      = getXxcsoSpDecRequestFullVO1();
//    if ( requestVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionHeaderFullVO1"
//        );
//    }
//   
//    XxcsoSpDecRequestFullVORowImpl requestRow
//      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();
//
//    requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_REQUEST);
//    // 2009-08-24 [障害0001104] Add End
//
//    validateAll(true);
//
//    XxcsoSpDecisionHeaderFullVORowImpl headerRow
//      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
//
//    NUMBER requestId = null;
//    OracleCallableStatement stmt = null;
//    try
//    {
//      StringBuffer sql = new StringBuffer(100);
//      sql.append("BEGIN");
//      sql.append("  :1 := fnd_request.submit_request(");
//      sql.append("          application       => 'XXCSO'");
//      sql.append("         ,program           => 'XXCSO020A04C'");
//      sql.append("         ,description       => NULL");
//      sql.append("         ,start_time        => NULL");
//      sql.append("         ,sub_request       => FALSE");
//      sql.append("         ,argument1         => :2");
//      sql.append("       );");
//      sql.append("END;");
//
//      stmt
//        = (OracleCallableStatement)
//            txn.createCallableStatement(sql.toString(), 0);
//
//      stmt.registerOutParameter(1, OracleTypes.NUMBER);
//      stmt.setString(2, headerRow.getSpDecisionHeaderId().stringValue());
//
//      stmt.execute();
//      
//      requestId = stmt.getNUMBER(1);
//    }
//    catch ( SQLException e )
//    {
//      XxcsoUtils.unexpected(txn, e);
//      throw
//        XxcsoMessage.createSqlErrorMessage(
//          e
//         ,XxcsoSpDecisionConstants.TOKEN_VALUE_IB_REQUEST
//        );
//    }
//    finally
//    {
//      try
//      {
//        if ( stmt != null )
//        {
//          stmt.close();
//        }
//      }
//      catch ( SQLException e )
//      {
//        XxcsoUtils.unexpected(txn, e);
//      }
//    }
//
//    if ( NUMBER.zero().equals(requestId) )
//    {
//      try
//      {
//        StringBuffer sql = new StringBuffer(50);
//        sql.append("BEGIN fnd_message.retrieve(:1); END;");
//
//        stmt
//          = (OracleCallableStatement)
//              txn.createCallableStatement(sql.toString(), 0);
//
//        stmt.registerOutParameter(1, OracleTypes.VARCHAR);
//
//        stmt.execute();
//
//        String errmsg = stmt.getString(1);
//
//        throw
//          XxcsoMessage.createErrorMessage(
//            XxcsoConstants.APP_XXCSO1_00310
//           ,XxcsoConstants.TOKEN_CONC
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_IB_REQUEST
//           ,XxcsoConstants.TOKEN_CONCMSG
//           ,errmsg
//          );
//      }
//      catch ( SQLException e )
//      {
//        XxcsoUtils.unexpected(txn, e);
//        throw
//          XxcsoMessage.createSqlErrorMessage(
//            e
//           ,XxcsoSpDecisionConstants.TOKEN_VALUE_IB_REQUEST
//          );
//      }
//      finally
//      {
//        try
//        {
//          if ( stmt != null )
//          {
//            stmt.close();
//          }
//        }
//        catch ( SQLException e )
//        {
//          XxcsoUtils.unexpected(txn, e);
//        }
//      }
//    }
//
//    commit();
//
//    OAException msg
//      = XxcsoMessage.createConfirmMessage(
//          XxcsoConstants.APP_XXCSO1_00001
//         ,XxcsoConstants.TOKEN_RECORD
//         ,XxcsoSpDecisionConstants.TOKEN_VALUE_REQUEST_CONC
//            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
//            + XxcsoConstants.TOKEN_VALUE_REQUEST_ID
//            + requestId.stringValue()
//            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
//         ,XxcsoConstants.TOKEN_ACTION
//         ,XxcsoSpDecisionConstants.TOKEN_VALUE_START
//        );
//
//    HashMap params = new HashMap(2);
//    params.put(
//      XxcsoConstants.EXECUTE_MODE
//     ,XxcsoSpDecisionConstants.DETAIL_MODE
//    );
//    params.put(
//      XxcsoConstants.TRANSACTION_KEY1
//     ,headerRow.getSpDecisionHeaderId()
//    );
//
//    HashMap returnValue = new HashMap(2);
//    returnValue.put(
//      XxcsoSpDecisionConstants.PARAM_URL_PARAM
//     ,params
//    );
//    returnValue.put(
//      XxcsoSpDecisionConstants.PARAM_MESSAGE
//     ,msg
//    );
//    
//    XxcsoUtils.debug(txn, "[END]");
//
//    return returnValue;
//  }
// 2016-01-08 [E_本稼動_13456] Del End

  
  /*****************************************************************************
   * 設置先と同じチェックボックスの変更イベント処理
   *****************************************************************************
   */
  public void handleSameInstallAccountFlagChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectContract(
      installVo
     ,cntrctVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * 取引条件選択の変更イベント処理
   * 全容器区分の変更イベント処理
   *****************************************************************************
   */
  public void handleConditionBusinessTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }

    XxcsoSpDecisionCcLineInitVOImpl ccLineInitVo
      = getXxcsoSpDecisionCcLineInitVO1();
    if ( ccLineInitVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCcLineInitVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectConditionBusiness(
      headerVo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,ccLineInitVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 売価別条件の行追加ボタン押下処理
   *****************************************************************************
   */
  public void handleScAddRowButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionScLineFullVOImpl scVo = getXxcsoSpDecisionScLineFullVO1();

    int lineSize = scVo.getRowCount();
    String maxLineSizeStr = txn.getProfile("XXCSO1_VIEW_SIZE_020_A01_01");

    if ( lineSize == Integer.parseInt(maxLineSizeStr) )
    {
      throw
        XxcsoMessage.createMaxRowException(
          XxcsoSpDecisionConstants.TOKEN_VALUE_SALES_COND
         ,maxLineSizeStr
        );
    }
    
    scVo.last();
    scVo.next();
    scVo.insertRow(scVo.createRow());
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 売価別条件の行削除ボタン押下処理
   *****************************************************************************
   */
  public void handleScDelRowButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();

    boolean existFlag = false;
    
    while ( scRow != null )
    {
      if ( "Y".equals(scRow.getSelectFlag()) )
      {
        existFlag = true;
        scVo.removeCurrentRow();
      }

      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    if ( ! existFlag )
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00290
        );
    }

    scVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * 定価換算率計算（売価別条件）ボタン押下処理
   *****************************************************************************
   */
  public void handleScCalcButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }
//E_本稼動_15904追加対応第3弾 Del Start
//    //E_本稼動_15904追加対応第3弾 Add Start
//    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
//      = getXxcsoSpDecisionBm1CustFullVO1();
//    if ( bm1Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm1CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
//      = getXxcsoSpDecisionBm2CustFullVO1();
//    if ( bm2Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm2CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
//      = getXxcsoSpDecisionBm3CustFullVO1();
//    if ( bm3Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm3CustFullVO1"
//        );
//    }
//    //E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End

    List errorList = new ArrayList();

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateScLine(
        txn
       ,headerVo
       ,scVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoSpDecisionCalculateUtils.calculateSalesCondition(
      txn
     ,headerVo
     ,scVo
//E_本稼動_15904追加対応第3弾 Del Start
////E_本稼動_15904追加対応第3弾 Add Start
//     ,bm1Vo
//     ,bm2Vo
//     ,bm3Vo
////E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End
    );

    scVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 定価換算率計算（全容器一律条件）ボタン押下処理
   *****************************************************************************
   */
  public void handleAllCcCalcButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }
//E_本稼動_15904追加対応第3弾 Del Start
//    //E_本稼動_15904追加対応第3弾 Add Start
//    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
//      = getXxcsoSpDecisionBm1CustFullVO1();
//    if ( bm1Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm1CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
//      = getXxcsoSpDecisionBm2CustFullVO1();
//    if ( bm2Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm2CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
//      = getXxcsoSpDecisionBm3CustFullVO1();
//    if ( bm3Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm3CustFullVO1"
//        );
//    }
//    //E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End
    List errorList = new ArrayList();

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateAllCcLine(
        txn
       ,headerVo
       ,allCcVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoSpDecisionCalculateUtils.calculateAllCcCondition(
      txn
     ,headerVo
     ,allCcVo
//E_本稼動_15904追加対応第3弾 Del Start
////E_本稼動_15904追加対応第3弾 Add Start
//     ,bm1Vo
//     ,bm2Vo
//     ,bm3Vo
////E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End
    );

    allCcVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 定価換算率計算（容器別条件）ボタン押下処理
   *****************************************************************************
   */
  public void handleSelCcCalcButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
//E_本稼動_15904追加対応第3弾 Del Start
//    //E_本稼動_15904追加対応第3弾 Add Start
//    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
//      = getXxcsoSpDecisionBm1CustFullVO1();
//    if ( bm1Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm1CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
//      = getXxcsoSpDecisionBm2CustFullVO1();
//    if ( bm2Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm2CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
//      = getXxcsoSpDecisionBm3CustFullVO1();
//    if ( bm3Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm3CustFullVO1"
//        );
//    }
//    //E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End
    List errorList = new ArrayList();

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateSelCcLine(
        txn
       ,headerVo
       ,selCcVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    XxcsoSpDecisionCalculateUtils.calculateSelCcCondition(
      txn
     ,headerVo
     ,selCcVo
//E_本稼動_15904追加対応第3弾 Del Start
////E_本稼動_15904追加対応第3弾 Add Start
//     ,bm1Vo
//     ,bm2Vo
//     ,bm3Vo
////E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del Start
    );

    selCcVo.first();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 送付先の変更イベント処理
   *****************************************************************************
   */
  public void handleBm1SendTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBmFormatVOImpl bmFmtVo
      = getXxcsoSpDecisionBmFormatVO1();
    if ( bmFmtVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBmFormatVO1"
        );
    }
    
    XxcsoSpDecisionReflectUtils.reflectBm1(
      headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bmFmtVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 支払条件・明細書（BM1）の変更イベント処理
   *****************************************************************************
   */
  public void handleBm1PaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
      
    String bm1SendType   = headerRow.getBm1SendType();
    String bmPaymentType = bm1Row.getBmPaymentType();
    String transferType  = bm1Row.getTransferCommissionType();
    
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bmPaymentType) )
    {
// 2010-03-01 [E_本稼動_01678] Add Start
      // 現金支払の場合
      if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bmPaymentType))
      {
        bm1Row.setTransferCommissionType(null);
      }
      else
      {
// 2010-03-01 [E_本稼動_01678] Add End
        if ( transferType == null || "".equals(transferType) )
        {
          bm1Row.setTransferCommissionType(
            XxcsoSpDecisionConstants.TRANSFER_CUST
          );
        }
// 2010-03-01 [E_本稼動_01678] Add Start
      }
// 2010-03-01 [E_本稼動_01678] Add End
      
      if ( bm1SendType == null || "".equals(bm1SendType) )
      {
        headerRow.setBm1SendType(XxcsoSpDecisionConstants.SEND_OTHER);
      }

      handleBm1SendTypeChange();
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 支払条件・明細書（BM2）の変更イベント処理
   *****************************************************************************
   */
  public void handleBm2PaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
      
    String bmPaymentType = bm2Row.getBmPaymentType();
    String transferType  = bm2Row.getTransferCommissionType();
    
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bmPaymentType) )
    {
// 2010-03-01 [E_本稼動_01678] Add Start
      // 現金支払の場合
      if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bmPaymentType))
      {
        bm2Row.setTransferCommissionType(null);
      }
      else
      {
// 2010-03-01 [E_本稼動_01678] Add End
        if ( transferType == null || "".equals(transferType) )
        {
          bm2Row.setTransferCommissionType(
            XxcsoSpDecisionConstants.TRANSFER_CUST
          );
        }
// 2010-03-01 [E_本稼動_01678] Add Start
      }
// 2010-03-01 [E_本稼動_01678] Add End
    }

    XxcsoSpDecisionReflectUtils.reflectBm2(
      headerVo
     ,installVo
     ,bm2Vo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 支払条件・明細書（BM3）の変更イベント処理
   *****************************************************************************
   */
  public void handleBm3PaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
      
    String bmPaymentType = bm3Row.getBmPaymentType();
    String transferType  = bm3Row.getTransferCommissionType();
    
    if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bmPaymentType) )
    {
// 2010-03-01 [E_本稼動_01678] Add Start
      // 現金支払の場合
      if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bmPaymentType))
      {
        bm3Row.setTransferCommissionType(null);
      }
      else
      {
// 2010-03-01 [E_本稼動_01678] Add End
        if ( transferType == null || "".equals(transferType) )
        {
          bm3Row.setTransferCommissionType(
            XxcsoSpDecisionConstants.TRANSFER_CUST
          );
        }
// 2010-03-01 [E_本稼動_01678] Add Start
      }
// 2010-03-01 [E_本稼動_01678] Add End
    }

    XxcsoSpDecisionReflectUtils.reflectBm3(
      headerVo
     ,installVo
     ,bm3Vo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

// 2009-03-23 [ST障害T1_0163] Add Start
  /*****************************************************************************
   * 電気代区分変更イベント処理
   *****************************************************************************
   */
  public void handleElectricityTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectElectricity(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }
// 2009-03-23 [ST障害T1_0163] Add End

// 2014-12-15 [E_本稼動_12565] Add Start
  /*****************************************************************************
   * 支払区分（行政財産使用料）変更イベント処理
   *****************************************************************************
   */
  public void handleAdAssetsTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectAdAssetsType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }

// Ver.1.22 Add Start
  /*****************************************************************************
   * 支払方法（行政財産使用料）変更イベント処理
   *****************************************************************************
   */
  public void handleAdAssetsPaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectAdAssetsPaymentType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }
// Ver.1.22 Add End

  /*****************************************************************************
   * 支払区分（設置協賛金）変更イベント処理
   *****************************************************************************
   */
  public void handleInstallSuppTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectInstallSuppType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 支払方法（設置協賛金）変更イベント処理
   *****************************************************************************
   */
  public void handleInstallSuppPaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectInstallSuppPaymentType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 支払区分（電気代区分）変更イベント処理
   *****************************************************************************
   */
  public void handleElectricTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectElectricType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 支払方法（電気代）変更イベント処理
   *****************************************************************************
   */
  public void handleElectricPaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectElectricPaymentType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 支払区分（紹介手数料）変更イベント処理
   *****************************************************************************
   */
  public void handleIntroChgTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectIntroChgType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 支払方法（紹介手数料）変更イベント処理
   *****************************************************************************
   */
  public void handleIntroChgPaymentTypeChange()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.reflectIntroChgPaymentType(
      headerVo
    );

    XxcsoUtils.debug(txn, "[END]");
  }

// 2014-12-15 [E_本稼動_12565] Add End

  /*****************************************************************************
   * 情報反映ボタン押下処理
   *****************************************************************************
   */
  public void handleReflectContractButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    List errorList
      = XxcsoSpDecisionValidateUtils.validateOtherCondition(
          txn
         ,headerVo
         ,false
// 2018-05-16 [E_本稼動_14989] Add Start
         ,installVo
// 2018-05-16 [E_本稼動_14989] Add End
        );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
// 2014-12-15 [E_本稼動_12565] Del Start    
//    XxcsoSpDecisionReflectUtils.reflectContent(
//      headerVo
//     ,installVo
//     ,bm1Vo
//    );
// 2014-12-15 [E_本稼動_12565] Del End
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 概算年間損益計算ボタン押下処理
   *****************************************************************************
   */
  public void handleCalcProfitButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }
    
    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
//E_本稼動_15904追加対応第3弾 Del Start
//    //E_本稼動_15904追加対応第3弾 Add Start
//    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
//      = getXxcsoSpDecisionBm1CustFullVO1();
//    if ( bm1Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm1CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
//      = getXxcsoSpDecisionBm2CustFullVO1();
//    if ( bm2Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm2CustFullVO1"
//        );
//    }
//
//    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
//      = getXxcsoSpDecisionBm3CustFullVO1();
//    if ( bm3Vo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError(
//          "XxcsoSpDecisionBm3CustFullVO1"
//        );
//    }
//    //E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    List errorList = new ArrayList();
    String condBizType = headerRow.getConditionBusinessType();
    String allContainerType = headerRow.getAllContainerType();

    /////////////////////////////////////
    // 値の確認
    /////////////////////////////////////
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      errorList.addAll(
        XxcsoSpDecisionValidateUtils.validateScLine(
          txn
         ,headerVo
         ,scVo
         ,true
        )
      );

      scVo.first();
    }
    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
       )
    {
      if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateAllCcLine(
            txn
           ,headerVo
           ,allCcVo
           ,true
          )
        );

        allCcVo.first();
      }
      else
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateSelCcLine(
            txn
           ,headerVo
           ,selCcVo
           ,true
          )
        );

        selCcVo.first();
      }
    }

    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateEstimateProfit(
        txn
       ,headerVo
       ,true
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }

    /////////////////////////////////////
    // 明細行の計算
    /////////////////////////////////////
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
      XxcsoSpDecisionCalculateUtils.calculateSalesCondition(
        txn
       ,headerVo
       ,scVo
//E_本稼動_15904追加対応第3弾 Del Start
////E_本稼動_15904追加対応第3弾 Add Start
//       ,bm1Vo
//       ,bm2Vo
//       ,bm3Vo
////E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End
      );

      scVo.first();
    }
    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)           ||
         XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
       )
    {
      if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
      {
        XxcsoSpDecisionCalculateUtils.calculateAllCcCondition(
          txn
         ,headerVo
         ,allCcVo
//E_本稼動_15904追加対応第3弾 Del Start
////E_本稼動_15904追加対応第3弾 Add Start
//         ,bm1Vo
//         ,bm2Vo
//         ,bm3Vo
////E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End
        );

        allCcVo.first();
      }
      else
      {
        XxcsoSpDecisionCalculateUtils.calculateSelCcCondition(
          txn
         ,headerVo
         ,selCcVo
//E_本稼動_15904追加対応第3弾 Del Start
////E_本稼動_15904追加対応第3弾 Add Start
//         ,bm1Vo
//         ,bm2Vo
//         ,bm3Vo
////E_本稼動_15904追加対応第3弾 Add End
//E_本稼動_15904追加対応第3弾 Del End
        );

        selCcVo.first();
      }
    }

    /////////////////////////////////////
    // 概算年間損益の計算
    /////////////////////////////////////
    XxcsoSpDecisionCalculateUtils.calculateEstimateYearProfit(
      txn
     ,headerVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 添付追加ボタン押下処理
   *****************************************************************************
   */
  public void handleAttachAddButton(
    String     fileName
   ,BlobDomain fileData
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    List errorList = new ArrayList();
    
    // インスタンス取得
    XxcsoSpDecisionInitVOImpl initVo
      = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }
    
    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();

    String excerpt = initRow.getAttachFileUpExcerpt();
    
    // 2009-08-24 [障害0001104] Add Start
    //if ( excerpt == null || "".equals(excerpt.trim()) )
    //{
    //  errorList.add(
    //    XxcsoMessage.createErrorMessage(
    //      XxcsoConstants.APP_XXCSO1_00005
    //     ,XxcsoConstants.TOKEN_COLUMN
    //     ,XxcsoSpDecisionConstants.TOKEN_VALUE_EXCERPT
    //    )
    //  );
    //}
    // 2009-08-24 [障害0001104] Add End
    
    int fileNameLen = fileName.getBytes().length;
    int maxFileNameLen = XxcsoSpDecisionConstants.MAX_ATTACH_FILE_NAME_LENGTH;
      
    if ( fileNameLen > maxFileNameLen )
    {
      errorList.add(
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00074
         ,XxcsoConstants.TOKEN_COLUMN
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_ATTACH_FILE_NAME
         ,XxcsoConstants.TOKEN_EMSIZE
         ,String.valueOf(maxFileNameLen / 2)
         ,XxcsoConstants.TOKEN_ONEBYTE
         ,String.valueOf(maxFileNameLen)
        )
      );
    }

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
    
    attachVo.last();
    attachVo.next();
    
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.createRow();

    attachRow.setFileName(fileName);
    attachRow.setExcerpt(excerpt);
    attachRow.setFileData(fileData);
    attachRow.setFullName(initRow.getFullName());

    attachVo.insertRow(attachRow);

    String a = initRow.getAttachFileUp();

    initRow.setAttachFileUpExcerpt(null);
    // 2009-08-24 [障害0001104] Add Start
    // 添付ファイルをクリア
    initRow.setAttachFileUp(null);
    // 2009-08-24 [障害0001104] Add End
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 添付削除ボタン押下処理
   *****************************************************************************
   */
  public void handleAttachDelButton()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // インスタンス取得
    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();

    boolean existFlag = false;
    while ( attachRow != null )
    {
      if ( "Y".equals(attachRow.getSelectFlag()) )
      {
        existFlag = true;
        attachVo.removeCurrentRow();
      }

      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }

    if ( ! existFlag )
    {
      throw
        XxcsoMessage.createErrorMessage(
          XxcsoConstants.APP_XXCSO1_00490
        );
    }
    
    attachVo.first();

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 各ポップリストの初期化処理
   *****************************************************************************
   */
  public void initPopList()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 申請区分
    XxcsoLookupListVOImpl appListVo
      = getXxcsoApplicationTypeListVO();
    if ( appListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoApplicationTypeListVO");
    }

    appListVo.initQuery(
      "XXCSO1_SP_APPLICATION_TYPE"
     ,"lookup_code"
    );
    
    // ステータス
    XxcsoLookupListVOImpl statusVo
      = getXxcsoStatusListVO();
    if ( statusVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoStatusListVO");
    }

    statusVo.initQuery(
      "XXCSO1_SP_STATUS_CD"
     ,"lookup_code"
    );
    
    // 業態（小分類）
    XxcsoBusinessCondTypeListVOImpl businessCondListVo
      = getXxcsoBusinessCondTypeListVO();
    if ( businessCondListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBusinessCondTypeListVO");
    }
    businessCondListVo.clearCache();
    
    // 業種
    XxcsoBusinessTypeListVOImpl businessListVo
      = getXxcsoBusinessTypeListVO1();
    if ( businessListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBusinessTypeListVO1");
    }

    // 設置場所
    XxcsoLookupListVOImpl installLocVo
      = getXxcsoInstallLocationListVO();
    if ( installLocVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallLocationListVO");
    }

    installLocVo.initQuery(
      "XXCMM_CUST_VD_SECCHI_BASYO"
     ,"lookup_code"
    );
    
    // オープン・クローズ
    XxcsoExtRefOpclTypeListVOImpl extRefOpclListVo
      = getXxcsoExtRefOpclTypeListVO();
    if ( extRefOpclListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoExtRefOpclTypeListVO");
    }

// 2016-01-08 [E_本稼動_13456] Del Start
//    // 新／旧
//    XxcsoLookupListVOImpl newOldListVo
//      = getXxcsoNewoldTypeListVO();
//    if ( newOldListVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError("XxcsoNewoldTypeListVO");
//    }
//
//    newOldListVo.initQuery(
//      "XXCSO1_CSI_JOB_KBN"
//     ,"attribute3 = '1'"
//     ,"TO_NUMBER(lookup_code)"
//    );
//    
//    // メーカーコード
//    XxcsoLookupListVOImpl makerCodeListVo
//      = getXxcsoMakerCodeListVO();
//    if ( makerCodeListVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError("XxcsoMakerCodeListVO");
//    }
//
//    makerCodeListVo.initQuery(
//      "XXCSO_CSI_MAKER_CODE"
//     ,"lookup_code"
//    );
//
//    // 規格内／外
//    XxcsoLookupListVOImpl standardListVo
//      = getXxcsoStandardTypeListVO();
//    if ( standardListVo == null )
//    {
//      throw
//        XxcsoMessage.createInstanceLostError("XxcsoStandardTypeListVO");
//    }
//
//    standardListVo.initQuery(
//      "XXCSO1_SP_VD_STANDARD_TYPE"
//     ,"lookup_code"
//    );
// 2016-01-08 [E_本稼動_13456] Del End
    
    // 取引条件
    XxcsoLookupListVOImpl condBizListVo
      = getXxcsoConditionBizTypeListVO();
    if ( condBizListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoConditionBizTypeListVO");
    }

    condBizListVo.initQuery(
      "XXCSO1_SP_BUSINESS_COND"
     ,"lookup_code"
    );
// [E_本稼動_15409] Add Start
    // BM1税区分
    XxcsoBM1TaxListVOImpl bm1TaxListVo
      = getXxcsoBM1TaxListVO1();
    if ( bm1TaxListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBM1TaxListVO");
    }
    // BM2税区分
    XxcsoLookupListVOImpl bm2TaxListVo
      = getXxcsoBM2TaxListVO1();
    if ( bm2TaxListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBM2TaxListVO");
    }
    bm2TaxListVo.initQuery(
      "XXCSO1_BM_TAX_KBN"
     ,"lookup_code"
    );
    // BM3税区分
    XxcsoLookupListVOImpl bm3TaxListVo
      = getXxcsoBM3TaxListVO1();
    if ( bm3TaxListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBM3TaxListVO");
    }
    bm3TaxListVo.initQuery(
      "XXCSO1_BM_TAX_KBN"
     ,"lookup_code"
    );
    
// [E_本稼動_15409] Add End
    // 定価
    XxcsoLookupListVOImpl fixedPriceListVo
      = getXxcsoFiexedPriceListVO();
    if ( fixedPriceListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoFiexedPriceListVO");
    }

    fixedPriceListVo.initQuery(
      "XXCSO1_SP_RULE_SELL_PRICE"
// 2009-04-27 [ST障害T1_0294] Mod Start
//     ,"lookup_code"
     ,"TO_NUMBER(lookup_code)"
// 2009-04-27 [ST障害T1_0294] Mod End
    );
// 2014-01-31 [E_本稼動_11397] Add Start
    // カード売区分
    XxcsoLookupListVOImpl cardSaleClassListVo
      = getXxcsoCardSaleClassListVO();
    if ( cardSaleClassListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCardSaleClassListVO");
    }

    cardSaleClassListVo.initQuery(
      "XXCOS1_CARD_SALE_CLASS"
     ,"lookup_code"
    );
// 2014-01-31 [E_本稼動_11397] Add End
    // 全容器区分
    XxcsoLookupListVOImpl allContainerListVo
      = getXxcsoAllContainerTypeListVO();
    if ( allContainerListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAllContainerTypeListVO");
    }

    allContainerListVo.initQuery(
      "XXCSO1_SP_ALL_CONTAINER_TYPE"
     ,"lookup_code"
    );
    
    // 容器区分
    XxcsoLookupListVOImpl ruleBottleListVo
      = getXxcsoRuleBottleTypeListVO();
    if ( ruleBottleListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoRuleBottleTypeListVO");
    }

    ruleBottleListVo.initQuery(
      "XXCSO1_SP_RULE_BOTTLE"
     ,"attribute4"
    );

// 2014-12-15 [E_本稼動_12565] Add Start
    // 中途解約条項
    XxcsoLookupListVOImpl cancellBeforeMaturityListVo
      = getXxcsoCancellBeforeMaturityListVO();
    if ( cancellBeforeMaturityListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCancellBeforeMaturityListVO");
    }

    cancellBeforeMaturityListVo.initQuery(
      "XXCSO1_SP_PRESENCE_OR_ABSENCE"
     ,"lookup_code"
    );

    // 税区分
    XxcsoLookupListVOImpl taxTypeVO
      = getXxcsoTaxTypeVO();
    if ( taxTypeVO == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTaxTypeVO");
    }

    taxTypeVO.initQuery(
      "XXCSO1_SP_TAX_DIVISION"
     ,"lookup_code"
    );

    // 支払方法（設置協賛金）
    XxcsoLookupListVOImpl installSuppPaymentTypeVO
      = getXxcsoInstallSuppPaymentTypeVO();
    if ( installSuppPaymentTypeVO == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoInstallSuppPaymentTypeVO");
    }

    installSuppPaymentTypeVO.initQuery(
      "XXCSO1_SP_INST_SUPP_PAY_TYPE"
// Ver.1.22 Mod Start
     //,"lookup_code"
     ,"attribute1"
// Ver.1.22 Mod End
    );

    // 支払方法（電気代）
    XxcsoLookupListVOImpl electricPaymentTypeV0
      = getXxcsoElectricPaymentTypeVO();
    if ( electricPaymentTypeV0 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoElectricPaymentTypeVO");
    }

    electricPaymentTypeV0.initQuery(
      "XXCSO1_SP_ELECTRIC_PAY_TYPE"
     ,"lookup_code"
    );

    // 支払方法（変動電気代）
    XxcsoLookupListVOImpl electricPaymentChageTypeV0
      = getXxcsoElectricPaymentChangeTypeVO();
    if ( electricPaymentChageTypeV0 == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoElectricPaymentChageTypeVO");
    }

    electricPaymentChageTypeV0.initQuery(
      "XXCSO1_SP_ELEC_PAY_CNG_TYPE"
     ,"lookup_code"
    );

    // 支払サイクル（電気代）
    XxcsoLookupListVOImpl electricPaymentCycleVO
      = getXxcsoElectricPaymentCycleVO();
    if ( electricPaymentCycleVO == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoElectricPaymentChageTypeVO");
    }

    electricPaymentCycleVO.initQuery(
      "XXCSO1_SP_ELEC_PAY_CYCLE"
     ,"lookup_code"
    );

    // 締日(電気代)、振込日(電気代)、締日(紹介手数料)、振込日(紹介手数料)
    XxcsoLookupListVOImpl daysListVo = getXxcsoDaysListVO();
    if ( daysListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoDaysListVO");
    }

    daysListVo.initQuery(
      "XXCSO1_DAYS_TYPE"
     ,"TO_NUMBER(lookup_code)"
    );

    // 振込月(電気代)、振込月（紹介手数料）
    XxcsoLookupListVOImpl monthsListVo = getXxcsoMonthsListVO();
    if ( monthsListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoMonthsListVO");
    }

    monthsListVo.initQuery(
      "XXCSO1_MONTHS_TYPE"
     ,"lookup_code"
    );
    // 支払方法（紹介手数料）
    XxcsoLookupListVOImpl introChgPaymentTypeVO
      = getXxcsoIntroChgPaymentTypeVO();
    if ( introChgPaymentTypeVO == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoIntroChgPaymentTypeVO");
    }

    introChgPaymentTypeVO.initQuery(
      "XXCSO1_SP_INTRO_CHG_PAY_TYPE"
     ,"lookup_code"
    );

// Ver.1.22 Add Start
    // 支払方法（行政財産使用料）
    XxcsoLookupListVOImpl adAssetsPaymentTypeVO
      = getXxcsoAdAssetsPaymentTypeVO();
    if ( adAssetsPaymentTypeVO == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoAdAssetsPaymentTypeVO");
    }

    adAssetsPaymentTypeVO.initQuery(
      "XXCSO1_SP_AD_ASSETS_PAY_TYPE"
     ,"attribute1"
    );
// Ver.1.22 Add End

// 2014-12-15 [E_本稼動_12565] Add End

    // 電気代
    XxcsoLookupListVOImpl electricityListVo
      = getXxcsoElectricityTypeListVO();
    if ( electricityListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoElectricityTypeListVO");
    }

    electricityListVo.initQuery(
      "XXCSO1_SP_ELECTRIC_BILL_TYPE"
// 2014-12-15 [E_本稼動_12565] Add Start
     ,"lookup_code <> '0'"
// 2014-12-15 [E_本稼動_12565] Add End
     ,"lookup_code"
    );

    // 送付先
    XxcsoLookupListVOImpl bm1SendListVo
      = getXxcsoBm1SendTypeListVO();
    if ( bm1SendListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBm1SendTypeListVO");
    }

    bm1SendListVo.initQuery(
      "XXCSO1_SP_SEND_TO_TYPE"
     ,"lookup_code"
    );

    // 振込手数料負担（BM1）
    XxcsoLookupListVOImpl bm1TransferListVo
      = getXxcsoTransferTypeListVO1();
    if ( bm1TransferListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferTypeListVO1");
    }

    bm1TransferListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // 振込手数料負担（BM2）
    XxcsoLookupListVOImpl bm2TransferListVo
      = getXxcsoTransferTypeListVO2();
    if ( bm2TransferListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferTypeListVO2");
    }

    bm2TransferListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // 振込手数料負担（BM3）
    XxcsoLookupListVOImpl bm3TransferListVo
      = getXxcsoTransferTypeListVO3();
    if ( bm3TransferListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoTransferTypeListVO3");
    }

    bm3TransferListVo.initQuery(
      "XXCSO1_SP_TRANSFER_FEE_TYPE"
     ,"lookup_code"
    );

    // 支払明細書（BM1）
    XxcsoLookupListVOImpl bm1PaymentListVo
      = getXxcsoBmPaymentTypeListVO1();
    if ( bm1PaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentTypeListVO1");
    }

    bm1PaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"attribute1 = 'Y'"
     ,"lookup_code"
    );

    // 支払明細書（BM2）
    XxcsoLookupListVOImpl bm2PaymentListVo
      = getXxcsoBmPaymentTypeListVO2();
    if ( bm2PaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentTypeListVO2");
    }

    bm2PaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"attribute1 = 'Y'"
     ,"lookup_code"
    );

    // 支払明細書（BM3）
    XxcsoLookupListVOImpl bm3PaymentListVo
      = getXxcsoBmPaymentTypeListVO3();
    if ( bm3PaymentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoBmPaymentTypeListVO3");
    }

    bm3PaymentListVo.initQuery(
      "XXCMM_BM_PAYMENT_KBN"
     ,"attribute1 = 'Y'"
     ,"lookup_code"
    );

    // 回送先選択範囲
    XxcsoLookupListVOImpl empAreaListVo
      = getXxcsoEmpAreaTypeListVO();
    if ( empAreaListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoEmpAreaTypeListVO");
    }

    empAreaListVo.initQuery(
      "XXCSO1_SP_EMPLOYEE_AREA"
     ,"lookup_code"
    );

    // 決裁内容
    XxcsoLookupListVOImpl spDecContentListVo
      = getXxcsoSpDecContentListVO();
    if ( spDecContentListVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoSpDecContentListVO");
    }

    spDecContentListVo.initQuery(
      "XXCSO1_SP_DECISION_CONTENT"
     ,"lookup_code"
    );

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 各表示属性の設定処理
   *****************************************************************************
   */
  public void setAttributeProperty()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // 使用するインスタンスを取得する    
    XxcsoSpDecisionInitVOImpl initVo = getXxcsoSpDecisionInitVO1();
    if ( initVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }
    
    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    ///////////////////////////////////////////
    // 本処理
    ///////////////////////////////////////////    
    XxcsoSpDecisionPropertyUtils.setAttributeProperty(
      initVo
     ,headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,attachVo
     ,sendVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * イベント前処理
   *****************************************************************************
   */
  public void afterProcess()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 使用するインスタンスを取得する    
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }
    
    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionReflectUtils.convValue(
      txn
     ,headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
    );
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 全リージョンの値検証
   * @param submitFlag       提出用フラグ
   *****************************************************************************
   */
  private void validateAll(
    boolean                              submitFlag
  )
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    
    List errorList = new ArrayList();  

    // インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInitVO1"
        );
    }

    XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
      = getXxcsoSpDecisionCntrctCustFullVO1();
    if ( cntrctVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionCntrctCustFullVO1"
        );
    }

    XxcsoSpDecisionBm1CustFullVOImpl bm1Vo
      = getXxcsoSpDecisionBm1CustFullVO1();
    if ( bm1Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm1CustFullVO1"
        );
    }

    XxcsoSpDecisionBm2CustFullVOImpl bm2Vo
      = getXxcsoSpDecisionBm2CustFullVO1();
    if ( bm2Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm2CustFullVO1"
        );
    }

    XxcsoSpDecisionBm3CustFullVOImpl bm3Vo
      = getXxcsoSpDecisionBm3CustFullVO1();
    if ( bm3Vo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBm3CustFullVO1"
        );
    }

    XxcsoSpDecisionScLineFullVOImpl scVo
      = getXxcsoSpDecisionScLineFullVO1();
    if ( scVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionScLineFullVO1"
        );
    }

    XxcsoSpDecisionAllCcLineFullVOImpl allCcVo
      = getXxcsoSpDecisionAllCcLineFullVO1();
    if ( allCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAllCcLineFullVO1"
        );
    }

    XxcsoSpDecisionSelCcLineFullVOImpl selCcVo
      = getXxcsoSpDecisionSelCcLineFullVO1();
    if ( selCcVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSelCcLineFullVO1"
        );
    }

    XxcsoSpDecisionAttachFullVOImpl attachVo
      = getXxcsoSpDecisionAttachFullVO1();
    if ( attachVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionAttachFullVO1"
        );
    }

    XxcsoSpDecisionSendFullVOImpl sendVo
      = getXxcsoSpDecisionSendFullVO1();
    if ( sendVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionSendFullVO1"
        );
    }

    XxcsoSpDecisionBmFormatVOImpl bmFmtVo
      = getXxcsoSpDecisionBmFormatVO1();
    if ( bmFmtVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionBmFormatVO1"
        );
    }

    // 2009-08-24 [障害0001104] Add Start
    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    // 2009-08-24 [障害0001104] Add End


    
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    XxcsoSpDecisionAttachFullVORowImpl attachRow
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    // 2009-08-24 [障害0001104] Add Start
    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();
    // 2009-08-24 [障害0001104] Add End


    /////////////////////////////////////
    // 概算年間損益の計算
    /////////////////////////////////////
    if ( submitFlag )
    {
      handleCalcProfitButton();
    }
    
    /////////////////////////////////////
    // 全リージョンの値反映
    /////////////////////////////////////
    XxcsoSpDecisionReflectUtils.reflectAll(
      headerVo
     ,installVo
     ,cntrctVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,bmFmtVo
    );

    /////////////////////////////////////
    // 検証処理：設置先
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateInstallCust(
        txn
       ,headerVo
       ,installVo
// 2009-11-29 [E_本稼動_00106] Add Start
       ,requestRow.getOperationMode()
// 2009-11-29 [E_本稼動_00106] Add End
       ,submitFlag
      )
    );
    /////////////////////////////////////
    // 検証処理：契約先
    /////////////////////////////////////
// 2009-04-14 [ST障害T1_0225] Mod Start
//    if ( ! "Y".equals(cntrctRow.getSameInstallAccountFlag()) )
//    {
//      errorList.addAll(
//        XxcsoSpDecisionValidateUtils.validateCntrctCust(
//          txn
//         ,headerVo
//         ,cntrctVo
//         ,submitFlag
//        )
//      );
//    }
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateCntrctCust(
        txn
       ,headerVo
       ,cntrctVo
       ,submitFlag
      )
    );
// 2009-04-14 [ST障害T1_0225] Mod End
// 2016-01-08 [E_本稼動_13456] Del Start
//    /////////////////////////////////////
//    // 検証処理：VD情報
//    /////////////////////////////////////
//    // 2009-08-24 [障害0001104] Add Start
//    // 申請区分が「新規」の場合、必須チェック。または「発注依頼」ボタンの場合
//    if ((XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(headerRow.getApplicationType()) ||
//        (XxcsoSpDecisionConstants.OPERATION_REQUEST.equals(requestRow.getOperationMode()))
//       ))
//    {
//    // 2009-08-24 [障害0001104] Add End
//      errorList.addAll(
//        XxcsoSpDecisionValidateUtils.validateVdInfo(
//          txn
//         ,headerVo
//         ,submitFlag
//        )
//      );
//    // 2009-08-24 [障害0001104] Add Start
//    }
//    else
//    {
//      errorList.addAll(
//        XxcsoSpDecisionValidateUtils.validateVdInfo(
//          txn
//         ,headerVo
//         ,false
//        )
//      );
//
//    }
// 2016-01-08 [E_本稼動_13456] Del End
    // 2009-08-24 [障害0001104] Add End
    /////////////////////////////////////
    // 検証処理：取引条件
    /////////////////////////////////////
    String condBizType = headerRow.getConditionBusinessType();
    String allContainerType = headerRow.getAllContainerType();
    boolean bm1CheckFlag = false;
    boolean bm2CheckFlag = false;
    boolean bm3CheckFlag = false;
    boolean contributeFlag = false;

    // 売価別条件のチェック
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType)             ||
         XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType)
       )
    {
// 2010-01-08 [E_本稼動_01031] Add Start
      errorList.addAll(
// 2010-01-08 [E_本稼動_01031] Add End
        XxcsoSpDecisionValidateUtils.validateScLine(
          txn
         ,headerVo
         ,scVo
// 2010-01-08 [E_本稼動_01031] Add Start
         //,submitFlag
         ,true
        )
// 2010-01-08 [E_本稼動_01031] Add End
      );
// 2010-01-08 [E_本稼動_01031] Add Start
      // エラーの場合は処理終了
      if ( errorList.size() > 0 )
      {
        OAException.raiseBundledOAException(errorList);
      }
// 2010-01-08 [E_本稼動_01031] Add End
      
      if ( XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType) )
      {
        contributeFlag = true;
      }
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
      while ( scRow != null )
      {
        String bm1BmRate = scRow.getBm1BmRate();
        String bm2BmRate = scRow.getBm2BmRate();
        String bm3BmRate = scRow.getBm3BmRate();
        String bm1BmAmt  = scRow.getBm1BmAmount();
        String bm2BmAmt  = scRow.getBm2BmAmount();
        String bm3BmAmt  = scRow.getBm3BmAmount();
// 課題一覧No.73対応 START
//        if ( bm1BmRate != null && ! "".equals(bm1BmRate) )
//        {
//          bm1CheckFlag = true;
//        }
//        if ( bm1BmAmt != null && ! "".equals(bm1BmAmt) )
//        {
//          bm1CheckFlag = true;
//        }
//        if ( bm2BmRate != null && ! "".equals(bm2BmRate) )
//        {
//          bm2CheckFlag = true;
//        }
//        if ( bm2BmAmt != null && ! "".equals(bm2BmAmt) )
//        {
//          bm2CheckFlag = true;
//        }
//        if ( bm3BmRate != null && ! "".equals(bm3BmRate) )
//        {
//          bm3CheckFlag = true;
//        }
//        if ( bm3BmAmt != null && ! "".equals(bm3BmAmt) )
//        {
//          bm3CheckFlag = true;
//        }

        if ( XxcsoSpDecisionValidateUtils.isBmInput(
                txn
               ,bm1BmRate
               ,bm1BmAmt
             )
           )
        {
          bm1CheckFlag = true;
        }

        if ( XxcsoSpDecisionValidateUtils.isBmInput(
               txn
              ,bm2BmRate
              ,bm2BmAmt
             )
           )
        {
          bm2CheckFlag = true;
        }

        if ( XxcsoSpDecisionValidateUtils.isBmInput(
               txn
              ,bm3BmRate
              ,bm3BmAmt
             )
           )
        {
          bm3CheckFlag = true;
        }
// 課題一覧No.73対応 END
        
        scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
      }

      scVo.first();
    }

    // 一律条件・容器別条件のチェック
    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType)             ||
         XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType)
       )
    {
      if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
      {
        contributeFlag = true;
      }
      
      if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
      {
// 2010-01-08 [E_本稼動_01031] Add Start
        errorList.addAll(
// 2010-01-08 [E_本稼動_01031] Add End
          XxcsoSpDecisionValidateUtils.validateAllCcLine(
            txn
           ,headerVo
           ,allCcVo
// 2010-01-08 [E_本稼動_01031] Add Start
           //,submitFlag
           ,true
          )
// 2010-01-08 [E_本稼動_01031] Add End
        );
// 2010-01-08 [E_本稼動_01031] Add Start
        // エラーの場合は処理終了
        if ( errorList.size() > 0 )
        {
          OAException.raiseBundledOAException(errorList);
        }
// 2010-01-08 [E_本稼動_01031] Add End
        allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
        while ( allCcRow != null )
        {
          String bm1BmRate = allCcRow.getBm1BmRate();
          String bm2BmRate = allCcRow.getBm2BmRate();
          String bm3BmRate = allCcRow.getBm3BmRate();
          String bm1BmAmt  = allCcRow.getBm1BmAmount();
          String bm2BmAmt  = allCcRow.getBm2BmAmount();
          String bm3BmAmt  = allCcRow.getBm3BmAmount();
// 課題一覧No.73対応 START
//          if ( bm1BmRate != null && ! "".equals(bm1BmRate) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm1BmAmt != null && ! "".equals(bm1BmAmt) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm2BmRate != null && ! "".equals(bm2BmRate) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm2BmAmt != null && ! "".equals(bm2BmAmt) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm3BmRate != null && ! "".equals(bm3BmRate) )
//          {
//            bm3CheckFlag = true;
//          }
//          if ( bm3BmAmt != null && ! "".equals(bm3BmAmt) )
//          {
//            bm3CheckFlag = true;
//          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm1BmRate
                ,bm1BmAmt
               )
             )
          {
            bm1CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm2BmRate
                ,bm2BmAmt
               )
             )
          {
            bm2CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm3BmRate
                ,bm3BmAmt
               )
             )
          {
            bm3CheckFlag = true;
          }
// 課題一覧No.73対応 END
          
          allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
        }

        allCcVo.first();
      }
      else
      {
// 2010-01-08 [E_本稼動_01031] Add Start
        errorList.addAll(
// 2010-01-08 [E_本稼動_01031] Add End
          XxcsoSpDecisionValidateUtils.validateSelCcLine(
            txn
           ,headerVo
           ,selCcVo
// 2010-01-08 [E_本稼動_01031] Add Start
           //,submitFlag
           ,true
          )
// 2010-01-08 [E_本稼動_01031] Add End
        );
// 2010-01-08 [E_本稼動_01031] Add Start
        // エラーの場合は処理終了
        if ( errorList.size() > 0 )
        {
          OAException.raiseBundledOAException(errorList);
        }
// 2010-01-08 [E_本稼動_01031] Add End
        selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
        while ( selCcRow != null )
        {
          String bm1BmRate = selCcRow.getBm1BmRate();
          String bm2BmRate = selCcRow.getBm2BmRate();
          String bm3BmRate = selCcRow.getBm3BmRate();
          String bm1BmAmt  = selCcRow.getBm1BmAmount();
          String bm2BmAmt  = selCcRow.getBm2BmAmount();
          String bm3BmAmt  = selCcRow.getBm3BmAmount();
// 課題一覧No.73対応 START
//          if ( bm1BmRate != null && ! "".equals(bm1BmRate) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm1BmAmt != null && ! "".equals(bm1BmAmt) )
//          {
//            bm1CheckFlag = true;
//          }
//          if ( bm2BmRate != null && ! "".equals(bm2BmRate) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm2BmAmt != null && ! "".equals(bm2BmAmt) )
//          {
//            bm2CheckFlag = true;
//          }
//          if ( bm3BmRate != null && ! "".equals(bm3BmRate) )
//          {
//            bm3CheckFlag = true;
//          }
//          if ( bm3BmAmt != null && ! "".equals(bm3BmAmt) )
//          {
//            bm3CheckFlag = true;
//          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm1BmRate
                ,bm1BmAmt
               )
             )
          {
            bm1CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm2BmRate
                ,bm2BmAmt
               )
             )
          {
            bm2CheckFlag = true;
          }

          if ( XxcsoSpDecisionValidateUtils.isBmInput(
                 txn
                ,bm3BmRate
                ,bm3BmAmt
               )
             )
          {
            bm3CheckFlag = true;
          }
// 課題一覧No.73対応 END
          
          selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
        }

        selCcVo.first();
      }
    }

// 2014-12-15 [E_本稼動_12565] Add Start
    String OperationMode = requestRow.getOperationMode();

// 2016-01-08 [E_本稼動_13456] Del Start
//    // 発注依頼ボタン以外の場合
//    if ( OperationMode != XxcsoSpDecisionConstants.OPERATION_REQUEST )
//    {
//// 2014-12-15 [E_本稼動_12565] Add End
// 2016-01-08 [E_本稼動_13456] Del End

      /////////////////////////////////////
      // 検証処理：その他条件
      /////////////////////////////////////
      errorList.addAll(
        XxcsoSpDecisionValidateUtils.validateOtherCondition(
          txn
         ,headerVo
         ,submitFlag
// 2018-05-16 [E_本稼動_14989] Add Start
         ,installVo
// 2018-05-16 [E_本稼動_14989] Add End
        )
      );

      errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateConditionReason(
        txn
       ,headerVo
       ,submitFlag
        )
      );
// 2014-12-15 [E_本稼動_12565] Add Start
      /////////////////////////////////////
      // 検証処理：覚書情報
      /////////////////////////////////////
      errorList.addAll(
        XxcsoSpDecisionValidateUtils.validateMemorandumInfo(
          txn
         ,headerVo
         ,submitFlag
        )
      );
// 2016-01-08 [E_本稼動_13456] Del Start
//    }
// 2016-01-08 [E_本稼動_13456] Del End
// 2014-12-15 [E_本稼動_12565] Add End
    /////////////////////////////////////
    // 検証処理：BM1
    /////////////////////////////////////
    String bizCondType = installRow.getBusinessConditionType();
    String elecType = headerRow.getElectricityType();
    String bm1PaymentType = bm1Row.getBmPaymentType();
    Number bm1CustomerId = bm1Row.getCustomerId();
    String bm1VendorName = bm1Row.getPartyName();
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.BIZ_COND_FULL_VD.equals(bizCondType) )
      {
        if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(elecType) ||
// 2010-11-11 [E_本稼動_01954] Add Start
             XxcsoSpDecisionConstants.ELEC_VALIABLE.equals(elecType) ||
// 2010-11-11 [E_本稼動_01954] Add End
             bm1CheckFlag
           )
        {
          errorList.addAll(
            XxcsoSpDecisionValidateUtils.validateBm1Cust(
              txn
             ,bm1Vo
             ,true
            )
          );
          // 2009-10-14 [IE554,IE573] Add Start
          //if ( isSameVendorExist(bm1CustomerId, bm1VendorName) )
          //{
          //  OAException error
          //    = XxcsoMessage.createErrorMessage(
          //        XxcsoConstants.APP_XXCSO1_00301
          //       ,XxcsoConstants.TOKEN_REGION
          //       ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
          //       ,XxcsoConstants.TOKEN_VENDOR
          //       ,bm1VendorName
          //      );
          //  errorList.add(error);
          //}
          // 2009-10-14 [IE554,IE573] Add End
        }
        else
        {
          if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(
                   bm1PaymentType
                 )
             )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00303
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM1_REGION
                );
            errorList.add(error);
          }
        }
      }
    }
    else
    {
      if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm1PaymentType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateBm1Cust(
            txn
           ,bm1Vo
           ,false
          )
        );
      }
    }

    /////////////////////////////////////
    // 検証処理：BM2
    /////////////////////////////////////
    String bm2PaymentType = bm2Row.getBmPaymentType();
    Number bm2CustomerId = bm2Row.getCustomerId();
    String bm2VendorName = bm2Row.getPartyName();
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.BIZ_COND_FULL_VD.equals(bizCondType) )
      {
        if ( bm2CheckFlag )
        {
          errorList.addAll(
            XxcsoSpDecisionValidateUtils.validateBm2Cust(
              txn
             ,headerVo
             ,bm2Vo
             ,true
            )
          );
          // 2009-10-14 [IE554,IE573] Add Start
          //if ( isSameVendorExist(bm2CustomerId, bm2VendorName) )
          //{
          //  String regionName = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION;
          //  if ( contributeFlag )
          //  {
          //    regionName
          //      = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION;
          //  }
          //  OAException error
          //    = XxcsoMessage.createErrorMessage(
          //        XxcsoConstants.APP_XXCSO1_00301
          //       ,XxcsoConstants.TOKEN_REGION
          //       ,regionName
          //       ,XxcsoConstants.TOKEN_VENDOR
          //       ,bm2VendorName
          //      );
          //  errorList.add(error);
          //}
          // 2009-10-14 [IE554,IE573] Add End
        }
        else
        {
          if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(
                   bm2PaymentType
                 )
             )
          {
            String regionName
              = XxcsoSpDecisionConstants.TOKEN_VALUE_BM2_REGION;
            if ( contributeFlag )
            {
              regionName
                = XxcsoSpDecisionConstants.TOKEN_VALUE_CONTRIBUTE_REGION;
            }
            
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00303
                 ,XxcsoConstants.TOKEN_REGION
                 ,regionName
                );
            errorList.add(error);
          }
        }
      }
    }
    else
    {
      if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm2PaymentType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateBm2Cust(
            txn
           ,headerVo
           ,bm2Vo
           ,false
          )
        );
      }
    }

    /////////////////////////////////////
    // 検証処理：BM3
    /////////////////////////////////////
    String bm3PaymentType = bm3Row.getBmPaymentType();
    Number bm3CustomerId = bm3Row.getCustomerId();
    String bm3VendorName = bm3Row.getPartyName();
    if ( submitFlag )
    {
      if ( XxcsoSpDecisionConstants.BIZ_COND_FULL_VD.equals(bizCondType) )
      {
        if ( bm3CheckFlag )
        {
          errorList.addAll(
            XxcsoSpDecisionValidateUtils.validateBm3Cust(
              txn
             ,bm3Vo
             ,true
            )
          );
          // 2009-10-14 [IE554,IE573] Add Start
          //if ( isSameVendorExist(bm3CustomerId, bm3VendorName) )
          //{
          //  OAException error
          //    = XxcsoMessage.createErrorMessage(
          //        XxcsoConstants.APP_XXCSO1_00301
          //       ,XxcsoConstants.TOKEN_REGION
          //       ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
          //       ,XxcsoConstants.TOKEN_VENDOR
          //       ,bm3VendorName
          //      );
          //  errorList.add(error);
          //}
          // 2009-10-14 [IE554,IE573] Add End
        }
        else
        {
          if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(
                   bm3PaymentType
                 )
             )
          {
            OAException error
              = XxcsoMessage.createErrorMessage(
                  XxcsoConstants.APP_XXCSO1_00303
                 ,XxcsoConstants.TOKEN_REGION
                 ,XxcsoSpDecisionConstants.TOKEN_VALUE_BM3_REGION
                );
            errorList.add(error);
          }
        }
      }
    }
    else
    {
      if ( ! XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm3PaymentType) )
      {
        errorList.addAll(
          XxcsoSpDecisionValidateUtils.validateBm3Cust(
            txn
           ,bm3Vo
           ,false
          )
        );
      }
    }

    /////////////////////////////////////
    // 検証処理：BM1/BM2/BM3の送付先コードの相互チェック
    /////////////////////////////////////
    boolean vendorIdDuplicateFlag = false;
    if ( bm1CustomerId != null )
    {
      if ( bm2CustomerId != null )
      {
        if ( bm1CustomerId.compareTo(bm2CustomerId) == 0 )
        {
          vendorIdDuplicateFlag = true;
        }
      }
      if ( bm3CustomerId != null )
      {
        if ( bm1CustomerId.compareTo(bm3CustomerId) == 0 )
        {
          vendorIdDuplicateFlag = true;
        }
      }
    }

    if ( bm2CustomerId != null )
    {
      if ( bm3CustomerId != null )
      {
        if ( bm2CustomerId.compareTo(bm3CustomerId) == 0 )
        {
          vendorIdDuplicateFlag = true;
        }
      }
    }

    if ( vendorIdDuplicateFlag )
    {
      if ( contributeFlag )
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00526)
        );
      }
      else
      {
        errorList.add(
          XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00521)
        );
      }
    }
    // [E_本稼動_16293] Add Start
    /////////////////////////////////////
    // 検証処理：BM1/BM2/BM3の仕入先無効日チェック
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateInbalidVendor(
         txn
        ,bm1Vo
        ,bm2Vo
        ,bm3Vo
        ,OperationMode
      )
    );
    // [E_本稼動_16293] Add End
    // [E_本稼動_15904] Add Start
    /////////////////////////////////////
    // 検証処理：BM1/BM2/BM3の税区分コードの妥当性チェック
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateBmTaxKbn(
         txn
        ,headerVo
        ,bm1Vo
        ,bm2Vo
        ,bm3Vo
        ,OperationMode
      )
    );
    // [E_本稼動_15904] Add End
    // 2009-10-14 [IE554,IE573] Add Start
    ///////////////////////////////////////
    //// 検証処理：BM1/BM2/BM3の送付先名の相互チェック
    ///////////////////////////////////////
    //boolean vendorNameDuplicateFlag = false;
    //if ( bm1VendorName != null && ! "".equals(bm1VendorName) )
    //{
    //  if ( bm2VendorName != null && ! "".equals(bm2VendorName) )
    //  {
    //    if ( bm1VendorName.equals(bm2VendorName) )
    //    {
    //      vendorNameDuplicateFlag = true;
    //    }
    //  }
    //  if ( bm3VendorName != null && ! "".equals(bm3VendorName) )
    //  {
    //    if ( bm1VendorName.equals(bm3VendorName) )
    //    {
    //      vendorNameDuplicateFlag = true;
    //    }
    //  }
    //}
    //
    //if ( bm2VendorName != null && ! "".equals(bm2VendorName) )
    //{
    //  if ( bm3VendorName != null && ! "".equals(bm3VendorName) )
    //  {
    //    if ( bm2VendorName.equals(bm3VendorName) )
    //    {
    //      vendorNameDuplicateFlag = true;
    //    }
    //  }
    //}
    //
    //if ( vendorNameDuplicateFlag )
    //{
    //  if ( contributeFlag )
    //  {
    //    errorList.add(
    //      XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00527)
    //    );
    //  }
    //  else
    //  {
    //    errorList.add(
    //      XxcsoMessage.createErrorMessage(XxcsoConstants.APP_XXCSO1_00522)
    //    );
    //  }
    //}
    // 2009-10-14 [IE554,IE573] Add End
// 2014-12-15 [E_本稼動_12565] Del Start
//    /////////////////////////////////////
//    // 検証処理：契約書への記載事項
//    /////////////////////////////////////
//    errorList.addAll(
//      XxcsoSpDecisionValidateUtils.validateContractContent(
//        txn
//       ,headerVo
//       ,submitFlag
//      )
//    );
// 2014-12-15 [E_本稼動_12565] Del End

    /////////////////////////////////////
    // 検証処理：概算年間損益
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateEstimateProfit(
        txn
       ,headerVo
       ,submitFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：添付
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateAttach(
        txn
       ,attachVo
       ,submitFlag
      )
    );

    /////////////////////////////////////
    // 検証処理：回送先
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateSend(
        txn
       ,headerVo
// 2010-03-01 [E_本稼動_01678] Add Start
       ,bm1Vo
       ,bm2Vo
       ,bm3Vo
// 2010-03-01 [E_本稼動_01678] Add End
       ,scVo
       ,allCcVo
       ,selCcVo
       ,sendVo
       ,submitFlag
      )
    );

    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
// 2010-01-15 [E_本稼動_00950] Add Start
    /////////////////////////////////////
    // 検証処理：ＤＢ値検証
    /////////////////////////////////////
    errorList.addAll(
      XxcsoSpDecisionValidateUtils.validateDb(
        txn
       ,headerVo
      )
    );
    if ( errorList.size() > 0 )
    {
      OAException.raiseBundledOAException(errorList);
    }
// 2010-01-15 [E_本稼動_00950] Add End
// 2010-03-01 [E_本稼動_01678] Add Start
// 2014-12-15 [E_本稼動_12565] Del Start
//    String OperationMode = requestRow.getOperationMode();
// 2014-12-15 [E_本稼動_12565] Del End
// 2014-12-15 [E_本稼動_12565] Add Start
    // 支払区分（電気代）が無しの場合
    if (XxcsoSpDecisionConstants.CHECK_NO.equals(headerRow.getElectricType()))
    {
      // 電気代区分に0(無し)を設定
      headerRow.setElectricityType(XxcsoSpDecisionConstants.ELEC_NONE);
    }
// 2014-12-15 [E_本稼動_12565] Add End

    // 提出、承認、確認ボタンの場合
    if (
        OperationMode == XxcsoSpDecisionConstants.OPERATION_SUBMIT ||
        OperationMode == XxcsoSpDecisionConstants.OPERATION_CONFIRM ||
        OperationMode == XxcsoSpDecisionConstants.OPERATION_APPROVE
       )
    {
      // BM1,2,3の支払方法・明細書が現金支払の場合
      if ( bm1CustomerId == null )
      {
        if (XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bm1Row.getBmPaymentType()))
        {
          if (bm1Row.getTransferCommissionType() != null && ! "".equals(bm1Row.getTransferCommissionType()))
          {
            // 振込手数料をNULLに更新
            bm1Row.setTransferCommissionType(null);
          }
        }
      }
      if ( bm2CustomerId == null )
      {
        if (XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bm2Row.getBmPaymentType()))
        {
          if (bm2Row.getTransferCommissionType() != null && ! "".equals(bm2Row.getTransferCommissionType()))
          {
            // 振込手数料をNULLに更新
            bm2Row.setTransferCommissionType(null);
          }
        }
      }
      if ( bm3CustomerId == null )
      {
        if (XxcsoSpDecisionConstants.PAYMENT_TYPE_CASH.equals(bm3Row.getBmPaymentType()))
        {
          if (bm3Row.getTransferCommissionType() != null && ! "".equals(bm3Row.getTransferCommissionType()))
          {
            // 振込手数料をNULLに更新
            bm3Row.setTransferCommissionType(null);
          }
        }
      }
    }
// 2010-03-01 [E_本稼動_01678] Add End
// 2016-01-08 [E_本稼動_13456] Del Start
//// 2013-04-19 [E_本稼動_09603] Add Start
//    // 発注依頼ボタンの場合
//    if ( OperationMode == XxcsoSpDecisionConstants.OPERATION_REQUEST )
//    {
//      String contractexists = headerRow.getContractExists();
//      // 契約の存在チェック
//      errorList.addAll(
//        XxcsoSpDecisionValidateUtils.validateContractExists(
//          txn
//         ,contractexists
//        )
//      );
//      if ( errorList.size() > 0 )
//      {
//        OAException.raiseBundledOAException(errorList);
//      }
//    }
//// 2013-04-19 [E_本稼動_09603] Add End
// 2016-01-08 [E_本稼動_13456] Del End
    XxcsoUtils.debug(txn, "[END]");
  }

// Ver.1.22 Add Start
  /*****************************************************************************
   * 支払期間開始日チェック
   *****************************************************************************
   */
    private void chkPayStartDate()
    {

      OADBTransaction txn = getOADBTransaction();

      XxcsoUtils.debug(txn, "[START]");

      List errorList = new ArrayList();
      
      //インスタンス取得
      XxcsoSpDecisionHeaderFullVOImpl headerVo
        = getXxcsoSpDecisionHeaderFullVO1();
      if ( headerVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoSpDecisionHeaderFullVO1"
          );
      }

      XxcsoSpDecisionInstCustFullVOImpl installVo
        = getXxcsoSpDecisionInstCustFullVO1();
      if ( installVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoSpDecisionInstCustFullVO1"
          );
      }
      
      errorList.addAll(
        XxcsoSpDecisionValidateUtils.chkPayStartDate(
           txn
          ,headerVo
          ,installVo
        )
      );

      if ( errorList.size() > 0 )
      {
        OAException.raiseBundledOAException(errorList);
      }

      XxcsoUtils.debug(txn, "[END]");
    }
// Ver.1.22 Add End


// Ver.1.22 Add Start
  /*****************************************************************************
   * メッセージを取得します。
   * @return mMessage
   *****************************************************************************
   */
  public OAException getMessage()
  {
    return mMessage;
  }

  /*****************************************************************************
   * 設置協賛金支払項目チェック処理
   *****************************************************************************
   */
  public void installPayItemCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.validateInstallPayItemCheck();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 設置協賛金支払項目チェック
   * @return OAException 
   *****************************************************************************
   */
  private OAException validateInstallPayItemCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    //変数初期化
    OAException  confirmMsg      = null;
    OracleCallableStatement stmt = null;
    String retCode               = null;
    String contractNumber        = null;
    String spNumber              = null; 
    String token1  = null;
    String token2  = null;
    String token3  = null;
    String token4  = null;
    // Ver.1.25 Add Start
    String token5  = null;
    // Ver.1.25 Add End

    //インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    // 行インスタンス取得
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl) headerVo.first();

    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl) installVo.first();

    String installSuppType   = headerRow.getInstallSuppType();

    Date installPayStartDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
              headerRow.getInstallPayStartYear(),
              headerRow.getInstallPayStartMonth());
              
    Date installPayEndDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
              headerRow.getInstallPayEndYear(),
              headerRow.getInstallPayEndMonth());
    
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(installSuppType) )
    {
      try
      {
        StringBuffer sql = new StringBuffer(100);
 
        sql.append("BEGIN");
        sql.append("  xxcso_020001j_pkg.chk_pay_item(");
        sql.append("    iv_account_number            => :1");
        sql.append("   ,id_pay_start_date            => :2");
        sql.append("   ,id_pay_end_date              => :3");
        sql.append("   ,iv_payment_type              => :4");
        sql.append("   ,in_amt                       => :5");
        sql.append("   ,iv_data_kbn                  => :6");
        sql.append("   ,iv_tax_type                  => :7");
        sql.append("   ,ov_contract_number           => :8");
        sql.append("   ,ov_sp_decision_number        => :9");
        sql.append("   ,ov_retcode                   => :10");
        sql.append("  );");
        sql.append("END;");

        XxcsoUtils.debug(txn, "execute = " + sql.toString());

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.setString(1, installRow.getInstallAccountNumber());
        stmt.setDATE(2, installPayStartDate);
        stmt.setDATE(3, installPayEndDate);
        stmt.setString(4,headerRow.getInstallSuppPaymentType());
        // Ver.1.25 Mod Start
        //stmt.setString(5,headerRow.getInstallSuppAmt().replaceAll(",", ""));
        // 支払条件（設置協賛金）
        String installSuppPaymentType = headerRow.getInstallSuppPaymentType();
        // 入力パラメータ「総額」
        String in_amt = "";
        //支払条件（設置協賛金）が2：総額払いの場合、総額（設置協賛金）を設定
        if(XxcsoSpDecisionConstants.TOTAL_PAY.equals(installSuppPaymentType)){
          in_amt = headerRow.getInstallSuppAmt().replaceAll(",", "");
        }
        // 総額払い以外の場合、今回支払（設置協賛金）を設定
        else
        {
          in_amt = headerRow.getInstallSuppThisTime().replaceAll(",", "");
        }    
        stmt.setString(5,in_amt);
        // Ver.1.25 Mod End
        stmt.setString(6, XxcsoSpDecisionConstants.INSTALL_SUPP_KBN);
        stmt.setString(7, headerRow.getTaxType());
        stmt.registerOutParameter(8, OracleTypes.VARCHAR);
        stmt.registerOutParameter(9, OracleTypes.VARCHAR);
        stmt.registerOutParameter(10, OracleTypes.VARCHAR);

        stmt.execute();
        contractNumber = stmt.getString(8);
        spNumber       = stmt.getString(9);
        retCode        = stmt.getString(10);

        // チェック結果が正常以外の場合、エラーメッセージを取得&戻り値に格納
        if ( !"0".equals(retCode) )
        {

          token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TAX_TYPE;
                 
          token2 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAYMENT_TYPE;

          token3 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_INSTALL_SUPP_AMT;
          // Ver.1.25 Mod Start
//          token4 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
//                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//                 + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_END_DATE;
          token4 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_THIS_TIME;
          token5 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_INSTALL_SUPP_PAY_END_DATE;
          // Ver.1.25 Mod End

          confirmMsg
            = XxcsoMessage.createWarningMessage(
                XxcsoConstants.APP_XXCSO1_00917
               ,XxcsoConstants.TOKEN_ITEM1
               ,token1
               ,XxcsoConstants.TOKEN_ITEM2
               ,token2
               ,XxcsoConstants.TOKEN_ITEM3
               ,token3
               ,XxcsoConstants.TOKEN_ITEM4
               ,token4
               // Ver.1.25 Add Start
               ,XxcsoConstants.TOKEN_ITEM5
               ,token5
               // Ver.1.25 Add End
               ,XxcsoConstants.TOKEN_SP_NUMBER
               ,spNumber
               ,XxcsoConstants.TOKEN_CONTRACT_NUMBER
               ,contractNumber
              );
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CHK_PAY_ITM
          );
      }
      finally
      {
        try
        {
          if ( stmt != null )
          {
            stmt.close();
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
        }
      }
    }
    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
  /*****************************************************************************
   * 行政財産使用料支払項目チェック処理
   *****************************************************************************
   */
  public void adAssetsPayItemCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    mMessage = this.validateAdAssetsPayItemCheck();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 行政財産使用料支払項目チェック
   * @return OAException 
   *****************************************************************************
   */
  private OAException validateAdAssetsPayItemCheck()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    //変数初期化
    OAException  confirmMsg      = null;
    OracleCallableStatement stmt = null;
    String retCode               = null;
    String contractNumber        = null;
    String spNumber              = null; 
    String token1  = null;
    String token2  = null;
    String token3  = null;  
    String token4  = null; 
    // Ver.1.25 Add Start
    String token5  = null;
    // Ver.1.25 Add End

    //インスタンス取得
    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecisionInstCustFullVOImpl installVo
      = getXxcsoSpDecisionInstCustFullVO1();
    if ( installVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionInstCustFullVO1"
        );
    }

    // 行インスタンス取得
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl) headerVo.first();

    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl) installVo.first();

    String adAssetsType      = headerRow.getAdAssetsType();
             
    Date adAssetsPayStartDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
              headerRow.getAdAssetsPayStartYear(),
              headerRow.getAdAssetsPayStartMonth());
              
    Date adAssetsPayEndDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
              headerRow.getAdAssetsPayEndYear(),
              headerRow.getAdAssetsPayEndMonth());
    
    if ( XxcsoSpDecisionConstants.CHECK_YES.equals(adAssetsType) )
    {
      try
      {
        StringBuffer sql = new StringBuffer(100);
 
        sql.append("BEGIN");
        sql.append("  xxcso_020001j_pkg.chk_pay_item(");
        sql.append("    iv_account_number            => :1");
        sql.append("   ,id_pay_start_date            => :2");
        sql.append("   ,id_pay_end_date              => :3");
        sql.append("   ,iv_payment_type              => :4");
        sql.append("   ,in_amt                       => :5");
        sql.append("   ,iv_data_kbn                  => :6");
        sql.append("   ,iv_tax_type                  => :7");
        sql.append("   ,ov_contract_number           => :8");
        sql.append("   ,ov_sp_decision_number        => :9");
        sql.append("   ,ov_retcode                   => :10");
        sql.append("  );");
        sql.append("END;");

        XxcsoUtils.debug(txn, "execute = " + sql.toString());

        stmt
          = (OracleCallableStatement)
              txn.createCallableStatement(sql.toString(), 0);

        stmt.setString(1, installRow.getInstallAccountNumber());
        stmt.setDATE(2, adAssetsPayStartDate);
        stmt.setDATE(3, adAssetsPayEndDate);       
        stmt.setString(4, headerRow.getAdAssetsPaymentType());
        // Ver.1.25 Mod Start
        //stmt.setString(5, headerRow.getAdAssetsAmt().replaceAll(",", ""));
        // 支払条件（行政財産使用料）
        String adAssetsPaymentType = headerRow.getAdAssetsPaymentType();
        // 入力パラメータ「総額」
        String in_amt = "";
        //支払条件（行政財産使用料）が2：総額払いの場合、総額（行政財産使用料）を設定
        if(XxcsoSpDecisionConstants.TOTAL_PAY.equals(adAssetsPaymentType)){
          in_amt = headerRow.getAdAssetsAmt().replaceAll(",", "");
        }
        // 総額払い以外の場合、今回支払（行政財産使用料）を設定
        else
        {
          in_amt = headerRow.getAdAssetsThisTime().replaceAll(",", "");
        }    
        stmt.setString(5, in_amt);
        // Ver.1.25 Mod End
        stmt.setString(6, XxcsoSpDecisionConstants.AD_ASSETS_KBN);
        stmt.setString(7, headerRow.getTaxType());
        stmt.registerOutParameter(8, OracleTypes.VARCHAR);
        stmt.registerOutParameter(9, OracleTypes.VARCHAR);
        stmt.registerOutParameter(10, OracleTypes.VARCHAR);

        stmt.execute();
        contractNumber = stmt.getString(8);
        spNumber       = stmt.getString(9);
        retCode        = stmt.getString(10);

        // チェック結果が正常以外の場合、エラーメッセージを取得&戻り値に格納
        if ( !"0".equals(retCode) )
        {
          token1 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TAX_TYPE;
                 
          token2 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAYMENT_TYPE;

          token3 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_AMT;
          // Ver.1.25 Mod Start
//          token4 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
//                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
//                 + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_END_DATE;
          token4 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_THIS_TIME;
          token5 = XxcsoSpDecisionConstants.TOKEN_VALUE_MEMO_RANDUM_INFO_REGION
                 + XxcsoConstants.TOKEN_VALUE_DELIMITER1
                 + XxcsoSpDecisionConstants.TOKEN_VALUE_AD_ASSETS_PAY_END_DATE;
          // Ver.1.25 Mod End
          
          confirmMsg
            = XxcsoMessage.createWarningMessage(
                XxcsoConstants.APP_XXCSO1_00917
               ,XxcsoConstants.TOKEN_ITEM1
               ,token1
               ,XxcsoConstants.TOKEN_ITEM2
               ,token2
               ,XxcsoConstants.TOKEN_ITEM3
               ,token3
               ,XxcsoConstants.TOKEN_ITEM4
               ,token4
               // Ver.1.25 Add Start
               ,XxcsoConstants.TOKEN_ITEM5
               ,token5
               // Ver.1.25 Add End
               ,XxcsoConstants.TOKEN_SP_NUMBER
               ,spNumber
               ,XxcsoConstants.TOKEN_CONTRACT_NUMBER
               ,contractNumber
              );
        }
      }
      catch ( SQLException e )
      {
        XxcsoUtils.unexpected(txn, e);
        throw
          XxcsoMessage.createSqlErrorMessage(
            e
           ,XxcsoSpDecisionConstants.TOKEN_VALUE_CHK_PAY_ITM
          );
      }
      finally
      {
        try
        {
          if ( stmt != null )
          {
            stmt.close();
          }
        }
        catch ( SQLException e )
        {
          XxcsoUtils.unexpected(txn, e);
        }
      }
    }
    XxcsoUtils.debug(txn, "[END]");

    return confirmMsg;
  }
// Ver.1.22 Add End

  /*****************************************************************************
   * コミット処理です。
   *****************************************************************************
   */
  private boolean isSameVendorExist(
    Number vendorId
   ,String vendorName
  )
  {
    boolean returnValue = false;
    
    if ( vendorId == null        &&
         vendorName != null      &&
         ! "".equals(vendorName)
       )
    {
      XxcsoSpDecisionVendorCheckVOImpl checkVo
        = getXxcsoSpDecisionVendorCheckVO1();
      if ( checkVo == null )
      {
        throw
          XxcsoMessage.createInstanceLostError(
            "XxcsoSpDecisionVendorCheckVO1"
          );
      }

      checkVo.initQuery(vendorName);

      if ( checkVo.first() != null )
      {
        returnValue = true;
      }
    }

    return returnValue;
  }


  
  /*****************************************************************************
   * コミット処理です。
   *****************************************************************************
   */
  private void commit()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    getTransaction().commit();

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * ロールバック処理です。
   *****************************************************************************
   */
  private void rollback()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    if ( getTransaction().isDirty() )
    {
      getTransaction().rollback();
    }

    XxcsoUtils.debug(txn, "[END]");
  }

// Ver.1.22 Add Start
  /*****************************************************************************
   * 確認ダイアログOKボタン押下時処理
   * @param   actionValue 提出or承認の文字列
   * @return  HashMap     再表示用情報格納Map
   *****************************************************************************
   */
  public HashMap handleConfirmOkButton(String actionValue)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoSpDecisionHeaderFullVOImpl headerVo
      = getXxcsoSpDecisionHeaderFullVO1();
    if ( headerVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "getXxcsoSpDecisionHeaderFullVO1"
        );
    }

    XxcsoSpDecRequestFullVOImpl requestVo
      = getXxcsoSpDecRequestFullVO1();
    if ( requestVo == null )
    {
      throw
        XxcsoMessage.createInstanceLostError(
          "XxcsoSpDecisionHeaderFullVO1"
        );
    }
    
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    Date installPayStartDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getInstallPayStartYear(),
                headerRow.getInstallPayStartMonth());
              
    Date installPayEndDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getInstallPayEndYear(),
                headerRow.getInstallPayEndMonth());
              
    Date adAssetsPayStartDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getAdAssetsPayStartYear(),
                headerRow.getAdAssetsPayStartMonth());
              
    Date adAssetsPayEndDate 
      = XxcsoSpDecisionValidateUtils.makeDate(
                headerRow.getAdAssetsPayEndYear(),
                headerRow.getAdAssetsPayEndMonth());

    // 支払期間開始日（設置協賛金）
    headerRow.setInstallPayStartDate(installPayStartDate);
    // 支払期間終了日（設置協賛金）
    headerRow.setInstallPayEndDate(installPayEndDate);
    // 支払期間開始日（行政財産使用料）
    headerRow.setAdAssetsPayStartDate(adAssetsPayStartDate);
    // 支払期間終了日（行政財産使用料）
    headerRow.setAdAssetsPayEndDate(adAssetsPayEndDate);

    XxcsoSpDecRequestFullVORowImpl requestRow
      = (XxcsoSpDecRequestFullVORowImpl)requestVo.first();

    
    if ( XxcsoSpDecisionConstants.TOKEN_VALUE_SUBMIT.equals(actionValue) )
    {
      requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_SUBMIT);
    }
    else if( XxcsoSpDecisionConstants.TOKEN_VALUE_APPROVE.equals(actionValue) )
    {
      requestRow.setOperationMode(XxcsoSpDecisionConstants.OPERATION_APPROVE);
    }

    commit();

    OAException msg
      = XxcsoMessage.createConfirmMessage(
          XxcsoConstants.APP_XXCSO1_00001
         ,XxcsoConstants.TOKEN_RECORD
         ,XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_SEP_LEFT
            + XxcsoSpDecisionConstants.TOKEN_VALUE_SP_DEC_NUM
            + headerRow.getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_SEP_RIGHT
         ,XxcsoConstants.TOKEN_ACTION
         ,actionValue
        );

    HashMap params = new HashMap(2);
    params.put(
      XxcsoConstants.EXECUTE_MODE
     ,XxcsoSpDecisionConstants.DETAIL_MODE
    );
    params.put(
      XxcsoConstants.TRANSACTION_KEY1
     ,headerRow.getSpDecisionHeaderId()
    );

    HashMap returnValue = new HashMap(2);
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_URL_PARAM
     ,params
    );
    returnValue.put(
      XxcsoSpDecisionConstants.PARAM_MESSAGE
     ,msg
    );
    
    XxcsoUtils.debug(txn, "[END]");

    return returnValue;

  }
// Ver.1.22 Add End

  /**
   * 
   * Sample main for debugging Business Components code using the tester.
   */
  public static void main(String[] args)
  {
    launchTester("itoen.oracle.apps.xxcso.xxcso020001j.server", "XxcsoSpDecisionRegistAMLocal");
  }

  /**
   * 
   * Container's getter for XxcsoInstallLocationListVO
   */
  public XxcsoLookupListVOImpl getXxcsoInstallLocationListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoInstallLocationListVO");
  }

  /**
   * 
   * Container's getter for XxcsoNewoldTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoNewoldTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoNewoldTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoMakerCodeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoMakerCodeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoMakerCodeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoConditionBizTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoConditionBizTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoConditionBizTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoFiexedPriceListVO
   */
  public XxcsoLookupListVOImpl getXxcsoFiexedPriceListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoFiexedPriceListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBm1SendTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoBm1SendTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBm1SendTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoTransferTypeListVO1
   */
  public XxcsoLookupListVOImpl getXxcsoTransferTypeListVO1()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoTransferTypeListVO2
   */
  public XxcsoLookupListVOImpl getXxcsoTransferTypeListVO2()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferTypeListVO2");
  }

  /**
   * 
   * Container's getter for XxcsoTransferTypeListVO3
   */
  public XxcsoLookupListVOImpl getXxcsoTransferTypeListVO3()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTransferTypeListVO3");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentTypeListVO1
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentTypeListVO1()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentTypeListVO2
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentTypeListVO2()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentTypeListVO2");
  }

  /**
   * 
   * Container's getter for XxcsoBmPaymentTypeListVO3
   */
  public XxcsoLookupListVOImpl getXxcsoBmPaymentTypeListVO3()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBmPaymentTypeListVO3");
  }

  /**
   * 
   * Container's getter for XxcsoEmpAreaTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoEmpAreaTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoEmpAreaTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBusinessCondTypeListVO
   */
  public XxcsoBusinessCondTypeListVOImpl getXxcsoBusinessCondTypeListVO()
  {
    return (XxcsoBusinessCondTypeListVOImpl)findViewObject("XxcsoBusinessCondTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoExtRefOpclTypeListVO
   */
  public XxcsoExtRefOpclTypeListVOImpl getXxcsoExtRefOpclTypeListVO()
  {
    return (XxcsoExtRefOpclTypeListVOImpl)findViewObject("XxcsoExtRefOpclTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoStandardTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoStandardTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoStandardTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoElectricityTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoElectricityTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoElectricityTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoApplicationTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoApplicationTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoApplicationTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoAllContainerTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoAllContainerTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoAllContainerTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderFullVO1
   */
  public XxcsoSpDecisionHeaderFullVOImpl getXxcsoSpDecisionHeaderFullVO1()
  {
    return (XxcsoSpDecisionHeaderFullVOImpl)findViewObject("XxcsoSpDecisionHeaderFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionInitVO1
   */
  public XxcsoSpDecisionInitVOImpl getXxcsoSpDecisionInitVO1()
  {
    return (XxcsoSpDecisionInitVOImpl)findViewObject("XxcsoSpDecisionInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionInstCustFullVO1
   */
  public XxcsoSpDecisionInstCustFullVOImpl getXxcsoSpDecisionInstCustFullVO1()
  {
    return (XxcsoSpDecisionInstCustFullVOImpl)findViewObject("XxcsoSpDecisionInstCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionCntrctCustFullVO1
   */
  public XxcsoSpDecisionCntrctCustFullVOImpl getXxcsoSpDecisionCntrctCustFullVO1()
  {
    return (XxcsoSpDecisionCntrctCustFullVOImpl)findViewObject("XxcsoSpDecisionCntrctCustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm1CustFullVO1
   */
  public XxcsoSpDecisionBm1CustFullVOImpl getXxcsoSpDecisionBm1CustFullVO1()
  {
    return (XxcsoSpDecisionBm1CustFullVOImpl)findViewObject("XxcsoSpDecisionBm1CustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm2CustFullVO1
   */
  public XxcsoSpDecisionBm2CustFullVOImpl getXxcsoSpDecisionBm2CustFullVO1()
  {
    return (XxcsoSpDecisionBm2CustFullVOImpl)findViewObject("XxcsoSpDecisionBm2CustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm3CustFullVO1
   */
  public XxcsoSpDecisionBm3CustFullVOImpl getXxcsoSpDecisionBm3CustFullVO1()
  {
    return (XxcsoSpDecisionBm3CustFullVOImpl)findViewObject("XxcsoSpDecisionBm3CustFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionScLineFullVO1
   */
  public XxcsoSpDecisionScLineFullVOImpl getXxcsoSpDecisionScLineFullVO1()
  {
    return (XxcsoSpDecisionScLineFullVOImpl)findViewObject("XxcsoSpDecisionScLineFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAllCcLineFullVO1
   */
  public XxcsoSpDecisionAllCcLineFullVOImpl getXxcsoSpDecisionAllCcLineFullVO1()
  {
    return (XxcsoSpDecisionAllCcLineFullVOImpl)findViewObject("XxcsoSpDecisionAllCcLineFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSelCcLineFullVO1
   */
  public XxcsoSpDecisionSelCcLineFullVOImpl getXxcsoSpDecisionSelCcLineFullVO1()
  {
    return (XxcsoSpDecisionSelCcLineFullVOImpl)findViewObject("XxcsoSpDecisionSelCcLineFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAttachFullVO1
   */
  public XxcsoSpDecisionAttachFullVOImpl getXxcsoSpDecisionAttachFullVO1()
  {
    return (XxcsoSpDecisionAttachFullVOImpl)findViewObject("XxcsoSpDecisionAttachFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSendFullVO1
   */
  public XxcsoSpDecisionSendFullVOImpl getXxcsoSpDecisionSendFullVO1()
  {
    return (XxcsoSpDecisionSendFullVOImpl)findViewObject("XxcsoSpDecisionSendFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderInstCustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderInstCustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderInstCustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderCntrctCustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderCntrctCustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderCntrctCustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm1CustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm1CustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm1CustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm2CustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm2CustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm2CustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm3CustVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm3CustVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm3CustVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderScLineVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderScLineVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderScLineVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAllCcLineVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAllCcLineVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAllCcLineVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSelCcLineVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSelCcLineVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSelCcLineVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAttachVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAttachVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAttachVL1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSendVL1
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSendVL1()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSendVL1");
  }

  /**
   * 
   * Container's getter for XxcsoStatusListVO
   */
  public XxcsoLookupListVOImpl getXxcsoStatusListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoStatusListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecContentListVO
   */
  public XxcsoLookupListVOImpl getXxcsoSpDecContentListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoSpDecContentListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBusinessTypeListVO1
   */
  public XxcsoBusinessTypeListVOImpl getXxcsoBusinessTypeListVO1()
  {
    return (XxcsoBusinessTypeListVOImpl)findViewObject("XxcsoBusinessTypeListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSendInitVO1
   */
  public XxcsoSpDecisionSendInitVOImpl getXxcsoSpDecisionSendInitVO1()
  {
    return (XxcsoSpDecisionSendInitVOImpl)findViewObject("XxcsoSpDecisionSendInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoRuleBottleTypeListVO
   */
  public XxcsoLookupListVOImpl getXxcsoRuleBottleTypeListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoRuleBottleTypeListVO");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionCcLineInitVO1
   */
  public XxcsoSpDecisionCcLineInitVOImpl getXxcsoSpDecisionCcLineInitVO1()
  {
    return (XxcsoSpDecisionCcLineInitVOImpl)findViewObject("XxcsoSpDecisionCcLineInitVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecRequestFullVO1
   */
  public XxcsoSpDecRequestFullVOImpl getXxcsoSpDecRequestFullVO1()
  {
    return (XxcsoSpDecRequestFullVOImpl)findViewObject("XxcsoSpDecRequestFullVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionVendorCheckVO1
   */
  public XxcsoSpDecisionVendorCheckVOImpl getXxcsoSpDecisionVendorCheckVO1()
  {
    return (XxcsoSpDecisionVendorCheckVOImpl)findViewObject("XxcsoSpDecisionVendorCheckVO1");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionHeaderFullVO2
   */
  public XxcsoSpDecisionHeaderFullVOImpl getXxcsoSpDecisionHeaderFullVO2()
  {
    return (XxcsoSpDecisionHeaderFullVOImpl)findViewObject("XxcsoSpDecisionHeaderFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionInstCustFullVO2
   */
  public XxcsoSpDecisionInstCustFullVOImpl getXxcsoSpDecisionInstCustFullVO2()
  {
    return (XxcsoSpDecisionInstCustFullVOImpl)findViewObject("XxcsoSpDecisionInstCustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionCntrctCustFullVO2
   */
  public XxcsoSpDecisionCntrctCustFullVOImpl getXxcsoSpDecisionCntrctCustFullVO2()
  {
    return (XxcsoSpDecisionCntrctCustFullVOImpl)findViewObject("XxcsoSpDecisionCntrctCustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm1CustFullVO2
   */
  public XxcsoSpDecisionBm1CustFullVOImpl getXxcsoSpDecisionBm1CustFullVO2()
  {
    return (XxcsoSpDecisionBm1CustFullVOImpl)findViewObject("XxcsoSpDecisionBm1CustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm2CustFullVO2
   */
  public XxcsoSpDecisionBm2CustFullVOImpl getXxcsoSpDecisionBm2CustFullVO2()
  {
    return (XxcsoSpDecisionBm2CustFullVOImpl)findViewObject("XxcsoSpDecisionBm2CustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBm3CustFullVO2
   */
  public XxcsoSpDecisionBm3CustFullVOImpl getXxcsoSpDecisionBm3CustFullVO2()
  {
    return (XxcsoSpDecisionBm3CustFullVOImpl)findViewObject("XxcsoSpDecisionBm3CustFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionScLineFullVO2
   */
  public XxcsoSpDecisionScLineFullVOImpl getXxcsoSpDecisionScLineFullVO2()
  {
    return (XxcsoSpDecisionScLineFullVOImpl)findViewObject("XxcsoSpDecisionScLineFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAllCcLineFullVO2
   */
  public XxcsoSpDecisionAllCcLineFullVOImpl getXxcsoSpDecisionAllCcLineFullVO2()
  {
    return (XxcsoSpDecisionAllCcLineFullVOImpl)findViewObject("XxcsoSpDecisionAllCcLineFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSelCcLineFullVO2
   */
  public XxcsoSpDecisionSelCcLineFullVOImpl getXxcsoSpDecisionSelCcLineFullVO2()
  {
    return (XxcsoSpDecisionSelCcLineFullVOImpl)findViewObject("XxcsoSpDecisionSelCcLineFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionAttachFullVO2
   */
  public XxcsoSpDecisionAttachFullVOImpl getXxcsoSpDecisionAttachFullVO2()
  {
    return (XxcsoSpDecisionAttachFullVOImpl)findViewObject("XxcsoSpDecisionAttachFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionSendFullVO2
   */
  public XxcsoSpDecisionSendFullVOImpl getXxcsoSpDecisionSendFullVO2()
  {
    return (XxcsoSpDecisionSendFullVOImpl)findViewObject("XxcsoSpDecisionSendFullVO2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderInstCustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderInstCustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderInstCustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderCntrctCustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderCntrctCustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderCntrctCustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm1CustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm1CustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm1CustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm2CustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm2CustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm2CustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderBm3CustVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderBm3CustVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderBm3CustVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderScLineVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderScLineVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderScLineVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAllCcLineVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAllCcLineVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAllCcLineVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSelCcLineVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSelCcLineVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSelCcLineVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderAttachVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderAttachVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderAttachVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecHeaderSendVL2
   */
  public ViewLinkImpl getXxcsoSpDecHeaderSendVL2()
  {
    return (ViewLinkImpl)findViewLink("XxcsoSpDecHeaderSendVL2");
  }

  /**
   * 
   * Container's getter for XxcsoSpDecisionBmFormatVO1
   */
  public XxcsoSpDecisionBmFormatVOImpl getXxcsoSpDecisionBmFormatVO1()
  {
    return (XxcsoSpDecisionBmFormatVOImpl)findViewObject("XxcsoSpDecisionBmFormatVO1");
  }

  /**
   * 
   * Container's getter for XxcsoCardSaleClassListVO
   */
  public XxcsoLookupListVOImpl getXxcsoCardSaleClassListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoCardSaleClassListVO");
  }

  /**
   * 
   * Container's getter for XxcsoCancellBeforeMaturityListVO
   */
  public XxcsoLookupListVOImpl getXxcsoCancellBeforeMaturityListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoCancellBeforeMaturityListVO");
  }

  /**
   * 
   * Container's getter for XxcsoTaxTypeVO
   */
  public XxcsoLookupListVOImpl getXxcsoTaxTypeVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoTaxTypeVO");
  }

  /**
   * 
   * Container's getter for XxcsoInstallSuppPaymentTypeVO
   */
  public XxcsoLookupListVOImpl getXxcsoInstallSuppPaymentTypeVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoInstallSuppPaymentTypeVO");
  }

  /**
   * 
   * Container's getter for XxcsoElectricTypeVO
   */
  public XxcsoLookupListVOImpl getXxcsoElectricTypeVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoElectricTypeVO");
  }

  /**
   * 
   * Container's getter for XxcsoElectricPaymentTypeVO
   */
  public XxcsoLookupListVOImpl getXxcsoElectricPaymentTypeVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoElectricPaymentTypeVO");
  }

  /**
   * 
   * Container's getter for XxcsoIntroChgPaymentTypeVO
   */
  public XxcsoLookupListVOImpl getXxcsoIntroChgPaymentTypeVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoIntroChgPaymentTypeVO");
  }

  /**
   * 
   * Container's getter for XxcsoElectricPaymentChangeTypeVO
   */
  public XxcsoLookupListVOImpl getXxcsoElectricPaymentChangeTypeVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoElectricPaymentChangeTypeVO");
  }

  /**
   * 
   * Container's getter for XxcsoElectricPaymentCycleVO
   */
  public XxcsoLookupListVOImpl getXxcsoElectricPaymentCycleVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoElectricPaymentCycleVO");
  }

  /**
   * 
   * Container's getter for XxcsoDaysListVO
   */
  public XxcsoLookupListVOImpl getXxcsoDaysListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoDaysListVO");
  }

  /**
   * 
   * Container's getter for XxcsoMonthsListVO
   */
  public XxcsoLookupListVOImpl getXxcsoMonthsListVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoMonthsListVO");
  }

  /**
   * 
   * Container's getter for XxcsoBM1TaxListVO1
   */
  public XxcsoBM1TaxListVOImpl getXxcsoBM1TaxListVO1()
  {
    return (XxcsoBM1TaxListVOImpl)findViewObject("XxcsoBM1TaxListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBM3TaxListVO1
   */
  public XxcsoLookupListVOImpl getXxcsoBM3TaxListVO1()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBM3TaxListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoBM2TaxListVO1
   */
  public XxcsoLookupListVOImpl getXxcsoBM2TaxListVO1()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoBM2TaxListVO1");
  }

  /**
   * 
   * Container's getter for XxcsoAdAssetsPaymentTypeVO
   */
  public XxcsoLookupListVOImpl getXxcsoAdAssetsPaymentTypeVO()
  {
    return (XxcsoLookupListVOImpl)findViewObject("XxcsoAdAssetsPaymentTypeVO");
  }










}