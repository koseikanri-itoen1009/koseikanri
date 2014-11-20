/*============================================================================
* ファイル名 : XxcsoSpDecisionPropertyUtils
* 概要説明   : SP専決表示属性プロパティ設定ユーティリティクラス
* バージョン : 1.7
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
* 2009-04-20 1.1  SCS柳平直人   [ST障害T1_0302]返却ボタン押下後表示不正対応
* 2009-05-13 1.2  SCS柳平直人   [ST障害T1_0954]T1_0302修正漏れ反映
* 2009-07-16 1.3  SCS阿部大輔   [SCS障害0000385]否決ボタン時の提出ボタン対応
* 2009-08-04 1.4  SCS小川浩     [SCS障害0000820]転勤時の適用・提出ボタン対応
* 2009-10-14 1.5  SCS阿部大輔   [共通課題IE554,IE573]住所対応
* 2011-04-25 1.6  SCS桐生和幸   [E_本稼動_07224]SP専決参照権限変更対応
* 2013-04-19 1.7  SCSK桐生和幸  [E_本稼動_09603]契約書未確定による顧客区分遷移の変更対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInitVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVORowImpl;

/*******************************************************************************
 * SP専決書の表示属性の設定を行うためのユーティリティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionPropertyUtils 
{
  /*****************************************************************************
   * 表示属性プロパティ設定
   * @param initVo        SP専決初期化用ビューインスタンス
   * @param headerVo      SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo     設置先登録／更新用ビューインスタンス
   * @param cntrctVo      契約先登録／更新用ビューインスタンス
   * @param bm1Vo         BM1登録／更新用ビューインスタンス
   * @param bm2Vo         BM2登録／更新用ビューインスタンス
   * @param bm3Vo         BM3登録／更新用ビューインスタンス
   * @param scVo          売価別条件登録／更新用ビューインスタンス
   * @param allCcVo       全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo       容器別条件登録／更新用ビューインスタンス
   * @param attachVo      添付登録／更新用ビューインスタンス
   * @param sendVo        回送先登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void setAttributeProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // 初期化
    /////////////////////////////////////
    initializeProperty(
      initVo
     ,scVo
     ,allCcVo
     ,selCcVo
     ,attachVo
     ,sendVo
    );

    /////////////////////////////////////
    // ベース設定
    /////////////////////////////////////
    setBaseProperty(
      initVo
     ,headerVo
     ,installVo
     ,bm1Vo
     ,bm2Vo
     ,bm3Vo
     ,sendVo
    );

    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();

    //////////////////////////////
    // ステータスによる表示／非表示
    //////////////////////////////
    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(headerRow.getStatus()) )
    {
      // 有効
      setEnableStatusProperty(
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
      );

    }
    else
    {
      // 有効以外
      setDetailProperty(
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
      );
    }

    setSendRegionProperty(
      initVo
     ,headerVo
     ,sendVo
    );
  }


  /*****************************************************************************
   * 表示属性プロパティ詳細設定
   * @param initVo        SP専決初期化用ビューインスタンス
   * @param headerVo      SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo     設置先登録／更新用ビューインスタンス
   * @param cntrctVo      契約先登録／更新用ビューインスタンス
   * @param bm1Vo         BM1登録／更新用ビューインスタンス
   * @param bm2Vo         BM2登録／更新用ビューインスタンス
   * @param bm3Vo         BM3登録／更新用ビューインスタンス
   * @param scVo          売価別条件登録／更新用ビューインスタンス
   * @param allCcVo       全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo       容器別条件登録／更新用ビューインスタンス
   * @param attachVo      添付登録／更新用ビューインスタンス
   *****************************************************************************
   */
  private static void setDetailProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
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

    String status              = headerRow.getStatus();
    String loginEmployeeNumber = initRow.getEmployeeNumber();
    String applicationCode     = headerRow.getApplicationCode();
    String applicationType     = headerRow.getApplicationType();
    String electricityType     = headerRow.getElectricityType();
    String custStatus          = installRow.getCustomerStatus();
    String sameInstAcctFlag    = cntrctRow.getSameInstallAccountFlag();
    String contractNumber      = cntrctRow.getContractNumber();
    String bm1SendType         = headerRow.getBm1SendType();
    String bm1VendorNumber     = bm1Row.getVendorNumber();
    String bm2VendorNumber     = bm2Row.getVendorNumber();
    String bm3VendorNumber     = bm3Row.getVendorNumber();
// 2013-04-19 [E_本稼動_09603] Add Start
    String updatecustenable    = installRow.getUpdateCustEnable();
    // 新規作成の場合は設置先顧客更新可能フラグに"Y"を設定
    if ( updatecustenable == null )
    {
      updatecustenable = "Y";
    }
// 2013-04-19 [E_本稼動_09603] Add End

    /////////////////////////////////////
    // 基本情報リージョン
    /////////////////////////////////////
    if ( XxcsoSpDecisionConstants.STATUS_INPUT.equals(status) )
    {
      initRow.setApplicationTypeViewRender(          Boolean.FALSE );
    }
    else
    {
      initRow.setApplicationTypeRender(              Boolean.FALSE );
    }

    /////////////////////////////////////
    // 設置先情報リージョン
    /////////////////////////////////////
    if ( ! loginEmployeeNumber.equals(applicationCode) )
    {
      // ログインユーザーが申請者でない場合、
      // すべて入力不可
      initRow.setInstallAcctNumber1Render(         Boolean.FALSE );
      initRow.setInstallAcctNumber2Render(         Boolean.FALSE );
      initRow.setInstallPartyNameRender(           Boolean.FALSE );
      initRow.setInstallPartyNameAltRender(        Boolean.FALSE );
      initRow.setInstallNameRender(                Boolean.FALSE );
      initRow.setInstallPostCdFRender(             Boolean.FALSE );
      initRow.setInstallPostCdSRender(             Boolean.FALSE );
      initRow.setInstallStateRender(               Boolean.FALSE );
      initRow.setInstallCityRender(                Boolean.FALSE );
      initRow.setInstallAddress1Render(            Boolean.FALSE );
      initRow.setInstallAddress2Render(            Boolean.FALSE );
      initRow.setInstallAddressLineRender(         Boolean.FALSE );
      initRow.setBizCondTypeRender(                Boolean.FALSE );
      initRow.setBusinessTypeRender(               Boolean.FALSE );
      initRow.setInstallLocationRender(            Boolean.FALSE );
      initRow.setExtRefOpclTypeRender(             Boolean.FALSE );
      initRow.setEmployeeNumberRender(             Boolean.FALSE );
      initRow.setPublishBaseCodeRender(            Boolean.FALSE );
      initRow.setInstallDateRender(                Boolean.FALSE );
      initRow.setInstallDateRequiredRender(        Boolean.FALSE );
      initRow.setLeaseCompanyRender(               Boolean.FALSE );
    }
    else
    {
      initRow.setInstallAcctNumberViewRender(      Boolean.FALSE );
      initRow.setInstallDateViewRender(            Boolean.FALSE );
      initRow.setInstallDateRequiredViewRender(    Boolean.FALSE );
      initRow.setLeaseCompanyViewRender(           Boolean.FALSE );

// 2013-04-19 [E_本稼動_09603] Mod Start
//      if ( custStatus == null                                              ||
//           XxcsoSpDecisionConstants.CUST_STATUS_MC_CAND.equals(custStatus) ||
//           XxcsoSpDecisionConstants.CUST_STATUS_MC.equals(custStatus)
//         )
      if ( 
          (custStatus == null                                              ||
           XxcsoSpDecisionConstants.CUST_STATUS_MC_CAND.equals(custStatus) ||
           XxcsoSpDecisionConstants.CUST_STATUS_MC.equals(custStatus)
          )
          &&
          (
               status != XxcsoSpDecisionConstants.STATUS_ENABLE &&
               "Y".equals(updatecustenable)
          )
         )
// 2013-04-19 [E_本稼動_09603] Mod End
      {
        // 顧客ステータスがNULL（新規）、MC候補、MCの場合、かつ、同一顧客で過去に承認済のSP専決がない場合
        // 入力可能
        initRow.setInstallAcctNumber2Render(       Boolean.FALSE );
        initRow.setInstallPartyNameViewRender(     Boolean.FALSE );
        initRow.setInstallPartyNameAltViewRender(  Boolean.FALSE );
        initRow.setInstallNameViewRender(          Boolean.FALSE );
        initRow.setInstallPostCdFViewRender(       Boolean.FALSE );
        initRow.setInstallPostCdSViewRender(       Boolean.FALSE );
        initRow.setInstallStateViewRender(         Boolean.FALSE );
        initRow.setInstallCityViewRender(          Boolean.FALSE );
        initRow.setInstallAddress1ViewRender(      Boolean.FALSE );
        initRow.setInstallAddress2ViewRender(      Boolean.FALSE );
        initRow.setInstallAddressLineViewRender(   Boolean.FALSE );
        initRow.setBizCondTypeViewRender(          Boolean.FALSE );
        initRow.setBusinessTypeViewRender(         Boolean.FALSE );
        initRow.setInstallLocationViewRender(      Boolean.FALSE );
        initRow.setExtRefOpclTypeViewRender(       Boolean.FALSE );
        initRow.setEmployeeNumberViewRender(       Boolean.FALSE );
        initRow.setPublishBaseCodeViewRender(      Boolean.FALSE );
      }
      else
      {
        // 顧客ステータスがNULL（新規）、MC候補、MC以外の場合、
        // 入力不可
        initRow.setInstallAcctNumber1Render(       Boolean.FALSE );
        initRow.setInstallPartyNameRender(         Boolean.FALSE );
        initRow.setInstallPartyNameAltRender(      Boolean.FALSE );
        initRow.setInstallNameRender(              Boolean.FALSE );
        initRow.setInstallPostCdFRender(           Boolean.FALSE );
        initRow.setInstallPostCdSRender(           Boolean.FALSE );
        initRow.setInstallStateRender(             Boolean.FALSE );
        initRow.setInstallCityRender(              Boolean.FALSE );
        initRow.setInstallAddress1Render(          Boolean.FALSE );
        initRow.setInstallAddress2Render(          Boolean.FALSE );
        initRow.setInstallAddressLineRender(       Boolean.FALSE );
        initRow.setBizCondTypeRender(              Boolean.FALSE );
        initRow.setBusinessTypeRender(             Boolean.FALSE );
        initRow.setInstallLocationRender(          Boolean.FALSE );
        initRow.setExtRefOpclTypeRender(           Boolean.FALSE );
        initRow.setEmployeeNumberRender(           Boolean.FALSE );
        initRow.setPublishBaseCodeRender(          Boolean.FALSE );
      }
    }

    /////////////////////////////////////
    // 契約先リージョン
    /////////////////////////////////////
    if ( "Y".equals(sameInstAcctFlag) )
    {
      // 設置先と同じにチェックが入っている場合は、
      // 入力不可
      // ただし、条件変更の場合は、
      // 契約先名、契約先名カナは入力可能
      initRow.setSameInstallAcctFlagViewRender(    Boolean.FALSE );
      initRow.setContractNumber1Render(            Boolean.FALSE );
      initRow.setContractNumber2Render(            Boolean.FALSE );
      if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(applicationType) )
      {
        initRow.setContractNameRender(             Boolean.FALSE );
        initRow.setContractNameAltRender(          Boolean.FALSE );
      }
      else
      {
        initRow.setContractNameViewRender(         Boolean.FALSE );
        initRow.setContractNameAltViewRender(      Boolean.FALSE );
      }
      initRow.setContractPostCdFRender(            Boolean.FALSE );
      initRow.setContractPostCdSRender(            Boolean.FALSE );
      initRow.setContractStateRender(              Boolean.FALSE );
      initRow.setContractCityRender(               Boolean.FALSE );
      initRow.setContractAddress1Render(           Boolean.FALSE );
      initRow.setContractAddress2Render(           Boolean.FALSE );
      initRow.setContractAddressLineRender(        Boolean.FALSE );
      initRow.setDelegateNameViewRender(           Boolean.FALSE );
    }
    else
    {
      initRow.setContractNumberViewRender(         Boolean.FALSE );
      if ( contractNumber == null || "".equals(contractNumber) )
      {
        // 契約先番号が入力されていない場合は、入力可能
        initRow.setSameInstallAcctFlagViewRender(  Boolean.FALSE );
        initRow.setContractNumber2Render(          Boolean.FALSE );
        initRow.setContractNameViewRender(         Boolean.FALSE );
        initRow.setContractNameAltViewRender(      Boolean.FALSE );
        initRow.setContractPostCdFViewRender(      Boolean.FALSE );
        initRow.setContractPostCdSViewRender(      Boolean.FALSE );
        initRow.setContractStateViewRender(        Boolean.FALSE );
        initRow.setContractCityViewRender(         Boolean.FALSE );
        initRow.setContractAddress1ViewRender(     Boolean.FALSE );
        initRow.setContractAddress2ViewRender(     Boolean.FALSE );
        initRow.setContractAddressLineViewRender(  Boolean.FALSE );
        initRow.setDelegateNameViewRender(         Boolean.FALSE );
      }
      else
      {
        initRow.setSameInstallAcctFlagRender(      Boolean.FALSE );
        initRow.setContractNumber1Render(          Boolean.FALSE );
        initRow.setContractNameRender(             Boolean.FALSE );
        initRow.setContractNameAltRender(          Boolean.FALSE );
        initRow.setContractPostCdFRender(          Boolean.FALSE );
        initRow.setContractPostCdSRender(          Boolean.FALSE );
        initRow.setContractStateRender(            Boolean.FALSE );
        initRow.setContractCityRender(             Boolean.FALSE );
        initRow.setContractAddress1Render(         Boolean.FALSE );
        initRow.setContractAddress2Render(         Boolean.FALSE );
        initRow.setContractAddressLineRender(      Boolean.FALSE );
        initRow.setDelegateNameRender(             Boolean.FALSE );
      }
    }

    /////////////////////////////////////
    // VD情報リージョン
    /////////////////////////////////////
    // すべて入力可能
    initRow.setNewoldTypeViewRender(               Boolean.FALSE );
    initRow.setSeleNumberViewRender(               Boolean.FALSE );
    initRow.setMakerCodeViewRender(                Boolean.FALSE );
    initRow.setStandardTypeViewRender(             Boolean.FALSE );
    initRow.setUnNumberViewRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // 取引条件選択リージョン
    /////////////////////////////////////
    // すべて入力可能
    initRow.setCondBizTypeViewRender(              Boolean.FALSE );

    /////////////////////////////////////
    // 売価別条件選択リージョン
    /////////////////////////////////////
    // すべて入力可能

    /////////////////////////////////////
    // 一律条件・容器別条件リージョン
    /////////////////////////////////////
    // すべて入力可能
    initRow.setAllContainerTypeViewRender(         Boolean.FALSE );

    /////////////////////////////////////
    // その他条件リージョン
    /////////////////////////////////////
    initRow.setContractYearDateViewRender(         Boolean.FALSE );
    initRow.setInstallSupportAmtViewRender(        Boolean.FALSE );
    initRow.setInstallSupportAmt2ViewRender(       Boolean.FALSE );
    initRow.setPaymentCycleViewRender(             Boolean.FALSE );
    initRow.setElectricityTypeViewRender(          Boolean.FALSE );
    initRow.setElectricityAmountViewRender(        Boolean.FALSE );
    initRow.setConditionReasonViewRender(          Boolean.FALSE );

    /////////////////////////////////////
    // BM1リージョン
    /////////////////////////////////////
    initRow.setBm1SendTypeViewRender(              Boolean.FALSE );
    if ( XxcsoSpDecisionConstants.SEND_SAME_INSTALL.equals(bm1SendType) ||
         XxcsoSpDecisionConstants.SEND_SAME_CNTRCT.equals(bm1SendType)
       )
    {
      // 送付先が設置先と同じ、契約先と同じの場合は、
      // 送付先、振込手数料負担、支払条件・明細書以外が入力不可
      initRow.setBm1VendorNumber1Render(           Boolean.FALSE );
      initRow.setBm1VendorNumber2Render(           Boolean.FALSE );
      initRow.setBm1VendorNameRender(              Boolean.FALSE );
      initRow.setBm1VendorNameAltRender(           Boolean.FALSE );
      initRow.setBm1PostCdFRender(                 Boolean.FALSE );
      initRow.setBm1PostCdSRender(                 Boolean.FALSE );
      initRow.setBm1StateRender(                   Boolean.FALSE );
      initRow.setBm1CityRender(                    Boolean.FALSE );
      initRow.setBm1Address1Render(                Boolean.FALSE );
      initRow.setBm1Address2Render(                Boolean.FALSE );
      initRow.setBm1AddressLineRender(             Boolean.FALSE );
      initRow.setBm1TransferTypeViewRender(        Boolean.FALSE );
      initRow.setBm1PaymentTypeViewRender(         Boolean.FALSE );
    }
    else
    {
      initRow.setBm1VendorNumberViewRender(        Boolean.FALSE );
      if ( bm1VendorNumber == null || "".equals(bm1VendorNumber) )
      {
        // 送付先コードがNULLの場合は、
        // 入力可能
        initRow.setBm1VendorNumber2Render(         Boolean.FALSE );
        initRow.setBm1VendorNameViewRender(        Boolean.FALSE );
        initRow.setBm1VendorNameAltViewRender(     Boolean.FALSE );
        initRow.setBm1PostCdFViewRender(           Boolean.FALSE );
        initRow.setBm1PostCdSViewRender(           Boolean.FALSE );
        initRow.setBm1StateViewRender(             Boolean.FALSE );
        initRow.setBm1CityViewRender(              Boolean.FALSE );
        initRow.setBm1Address1ViewRender(          Boolean.FALSE );
        initRow.setBm1Address2ViewRender(          Boolean.FALSE );
        initRow.setBm1AddressLineViewRender(       Boolean.FALSE );
        initRow.setBm1TransferTypeViewRender(      Boolean.FALSE );
        initRow.setBm1PaymentTypeViewRender(       Boolean.FALSE );
      }
      else
      {
        initRow.setBm1VendorNumber1Render(         Boolean.FALSE );
        initRow.setBm1VendorNameRender(            Boolean.FALSE );
        initRow.setBm1VendorNameAltRender(         Boolean.FALSE );
        initRow.setBm1PostCdFRender(               Boolean.FALSE );
        initRow.setBm1PostCdSRender(               Boolean.FALSE );
        initRow.setBm1StateRender(                 Boolean.FALSE );
        initRow.setBm1CityRender(                  Boolean.FALSE );
        initRow.setBm1Address1Render(              Boolean.FALSE );
        initRow.setBm1Address2Render(              Boolean.FALSE );
        initRow.setBm1AddressLineRender(           Boolean.FALSE );
        initRow.setBm1TransferTypeRender(          Boolean.FALSE );
        initRow.setBm1PaymentTypeRender(           Boolean.FALSE );
      }
    }

    /////////////////////////////////////
    // BM2リージョン
    /////////////////////////////////////
    initRow.setBm2VendorNumberViewRender(          Boolean.FALSE );
    if ( bm2VendorNumber == null || "".equals(bm2VendorNumber) )
    {
      // 送付先コードがNULLの場合は、
      // 入力可能
      initRow.setBm2VendorNumber2Render(           Boolean.FALSE );
      initRow.setBm2VendorNameViewRender(          Boolean.FALSE );
      initRow.setBm2VendorNameAltViewRender(       Boolean.FALSE );
      initRow.setBm2PostCdFViewRender(             Boolean.FALSE );
      initRow.setBm2PostCdSViewRender(             Boolean.FALSE );
      initRow.setBm2StateViewRender(               Boolean.FALSE );
      initRow.setBm2CityViewRender(                Boolean.FALSE );
      initRow.setBm2Address1ViewRender(            Boolean.FALSE );
      initRow.setBm2Address2ViewRender(            Boolean.FALSE );
      initRow.setBm2AddressLineViewRender(         Boolean.FALSE );
      initRow.setBm2TransferTypeViewRender(        Boolean.FALSE );
      initRow.setBm2PaymentTypeViewRender(         Boolean.FALSE );
    }
    else
    {
      initRow.setBm2VendorNumber1Render(           Boolean.FALSE );
      initRow.setBm2VendorNameRender(              Boolean.FALSE );
      initRow.setBm2VendorNameAltRender(           Boolean.FALSE );
      initRow.setBm2PostCdFRender(                 Boolean.FALSE );
      initRow.setBm2PostCdSRender(                 Boolean.FALSE );
      initRow.setBm2StateRender(                   Boolean.FALSE );
      initRow.setBm2CityRender(                    Boolean.FALSE );
      initRow.setBm2Address1Render(                Boolean.FALSE );
      initRow.setBm2Address2Render(                Boolean.FALSE );
      initRow.setBm2AddressLineRender(             Boolean.FALSE );
      initRow.setBm2TransferTypeRender(            Boolean.FALSE );
      initRow.setBm2PaymentTypeRender(             Boolean.FALSE );
    }

    /////////////////////////////////////
    // BM3リージョン
    /////////////////////////////////////
    initRow.setBm3VendorNumberViewRender(          Boolean.FALSE );
    if ( bm3VendorNumber == null || "".equals(bm3VendorNumber) )
    {
      // 送付先コードがNULLの場合は、
      // 入力可能
      initRow.setBm3VendorNumber2Render(           Boolean.FALSE );
      initRow.setBm3VendorNameViewRender(          Boolean.FALSE );
      initRow.setBm3VendorNameAltViewRender(       Boolean.FALSE );
      initRow.setBm3PostCdFViewRender(             Boolean.FALSE );
      initRow.setBm3PostCdSViewRender(             Boolean.FALSE );
      initRow.setBm3StateViewRender(               Boolean.FALSE );
      initRow.setBm3CityViewRender(                Boolean.FALSE );
      initRow.setBm3Address1ViewRender(            Boolean.FALSE );
      initRow.setBm3Address2ViewRender(            Boolean.FALSE );
      initRow.setBm3AddressLineViewRender(         Boolean.FALSE );
      initRow.setBm3TransferTypeViewRender(        Boolean.FALSE );
      initRow.setBm3PaymentTypeViewRender(         Boolean.FALSE );
    }
    else
    {
      initRow.setBm3VendorNumber1Render(           Boolean.FALSE );
      initRow.setBm3VendorNameRender(              Boolean.FALSE );
      initRow.setBm3VendorNameAltRender(           Boolean.FALSE );
      initRow.setBm3PostCdFRender(                 Boolean.FALSE );
      initRow.setBm3PostCdSRender(                 Boolean.FALSE );
      initRow.setBm3StateRender(                   Boolean.FALSE );
      initRow.setBm3CityRender(                    Boolean.FALSE );
      initRow.setBm3Address1Render(                Boolean.FALSE );
      initRow.setBm3Address2Render(                Boolean.FALSE );
      initRow.setBm3AddressLineRender(             Boolean.FALSE );
      initRow.setBm3TransferTypeRender(            Boolean.FALSE );
      initRow.setBm3PaymentTypeRender(             Boolean.FALSE );
    }

    /////////////////////////////////////
    // 契約書への記載事項リージョン
    /////////////////////////////////////
    // すべて入力可能
    initRow.setOtherContentViewRender(             Boolean.FALSE );

    /////////////////////////////////////
    // 概算年間損益リージョン
    /////////////////////////////////////
    // すべて入力可能
    initRow.setSalesMonthViewRender(               Boolean.FALSE );
    initRow.setBmRateViewRender(                   Boolean.FALSE );
    initRow.setLeaseChargeMonthViewRender(         Boolean.FALSE );
    initRow.setConstructionChargeViewRender(       Boolean.FALSE );
    initRow.setElectricityAmtMonthViewRender(      Boolean.FALSE );

    /////////////////////////////////////
    // 添付リージョン
    /////////////////////////////////////
    // すべて入力可能
  }


  /*****************************************************************************
   * 有効時表示属性プロパティ設定
   * @param initVo        SP専決初期化用ビューインスタンス
   * @param headerVo      SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo     設置先登録／更新用ビューインスタンス
   * @param cntrctVo      契約先登録／更新用ビューインスタンス
   * @param bm1Vo         BM1登録／更新用ビューインスタンス
   * @param bm2Vo         BM2登録／更新用ビューインスタンス
   * @param bm3Vo         BM3登録／更新用ビューインスタンス
   * @param scVo          売価別条件登録／更新用ビューインスタンス
   * @param allCcVo       全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo       容器別条件登録／更新用ビューインスタンス
   * @param attachVo      添付登録／更新用ビューインスタンス
   *****************************************************************************
   */
  private static void setEnableStatusProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl  cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
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
    
    /////////////////////////////////////
    // 基本情報リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setApplicationTypeRender(              Boolean.FALSE );

    /////////////////////////////////////
    // 設置先情報リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setInstallAcctNumber1Render(           Boolean.FALSE );
    initRow.setInstallAcctNumber2Render(           Boolean.FALSE );
    initRow.setInstallPartyNameRender(             Boolean.FALSE );
    initRow.setInstallPartyNameAltRender(          Boolean.FALSE );
    initRow.setInstallNameRender(                  Boolean.FALSE );
    initRow.setInstallPostCdFRender(               Boolean.FALSE );
    initRow.setInstallPostCdSRender(               Boolean.FALSE );
    initRow.setInstallStateRender(                 Boolean.FALSE );
    initRow.setInstallCityRender(                  Boolean.FALSE );
    initRow.setInstallAddress1Render(              Boolean.FALSE );
    initRow.setInstallAddress2Render(              Boolean.FALSE );
    initRow.setInstallAddressLineRender(           Boolean.FALSE );
    initRow.setBizCondTypeRender(                  Boolean.FALSE );
    initRow.setBusinessTypeRender(                 Boolean.FALSE );
    initRow.setInstallLocationRender(              Boolean.FALSE );
    initRow.setExtRefOpclTypeRender(               Boolean.FALSE );
    initRow.setEmployeeNumberRender(               Boolean.FALSE );
    initRow.setPublishBaseCodeRender(              Boolean.FALSE );
    initRow.setInstallDateRender(                  Boolean.FALSE );
    initRow.setInstallDateRequiredRender(          Boolean.FALSE );
    initRow.setLeaseCompanyRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // 契約先リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setSameInstallAcctFlagRender(          Boolean.FALSE );
    initRow.setContractNumber1Render(              Boolean.FALSE );
    initRow.setContractNumber2Render(              Boolean.FALSE );
    initRow.setContractNameRender(                 Boolean.FALSE );
    initRow.setContractNameAltRender(              Boolean.FALSE );
    initRow.setContractPostCdFRender(              Boolean.FALSE );
    initRow.setContractPostCdSRender(              Boolean.FALSE );
    initRow.setContractStateRender(                Boolean.FALSE );
    initRow.setContractCityRender(                 Boolean.FALSE );
    initRow.setContractAddress1Render(             Boolean.FALSE );
    initRow.setContractAddress2Render(             Boolean.FALSE );
    initRow.setContractAddressLineRender(          Boolean.FALSE );
    initRow.setDelegateNameRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // VD情報リージョン
    /////////////////////////////////////
    if ( Boolean.TRUE.equals(initRow.getRequestButtonRender()) )
    {
      // 発注依頼ボタンを押せるユーザーのみが入力可能
      String newoldType = headerRow.getNewoldType();
      if ( XxcsoSpDecisionConstants.NEW_OLD_OLD.equals(newoldType) )
      {
        // 旧台の場合は、入力不可
        initRow.setNewoldTypeRender(               Boolean.FALSE );
      }
      else
      {
        initRow.setNewoldTypeViewRender(           Boolean.FALSE );
      }
      initRow.setSeleNumberViewRender(             Boolean.FALSE );
      initRow.setMakerCodeViewRender(              Boolean.FALSE );
      initRow.setStandardTypeViewRender(           Boolean.FALSE );
      initRow.setUnNumberViewRender(               Boolean.FALSE );
    }
    else
    {
      // 発注依頼ボタンを押せないユーザーは入力不可
      initRow.setNewoldTypeRender(                 Boolean.FALSE );
      initRow.setSeleNumberRender(                 Boolean.FALSE );
      initRow.setMakerCodeRender(                  Boolean.FALSE );
      initRow.setStandardTypeRender(               Boolean.FALSE );
      initRow.setUnNumberRender(                   Boolean.FALSE );
    }

    /////////////////////////////////////
    // 取引条件選択リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setCondBizTypeRender(                  Boolean.FALSE );

    /////////////////////////////////////
    // 売価別条件選択リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setScActionFlRNRender(                 Boolean.FALSE );
    initRow.setScTableFooterRender(                Boolean.FALSE );
    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    while ( scRow != null )
    {
      scRow.setFixedPriceReadOnly(                 Boolean.TRUE  );
      scRow.setSalesPriceReadOnly(                 Boolean.TRUE  );
      scRow.setScBm1BmRateReadOnly(                Boolean.TRUE  );
      scRow.setScBm1BmAmountReadOnly(              Boolean.TRUE  );
      scRow.setScBm2BmRateReadOnly(                Boolean.TRUE  );
      scRow.setScBm2BmAmountReadOnly(              Boolean.TRUE  );
      scRow.setScBm3BmRateReadOnly(                Boolean.TRUE  );
      scRow.setScBm3BmAmountReadOnly(              Boolean.TRUE  );
      scRow.setScMultipleSelectionRender(          Boolean.FALSE );
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    /////////////////////////////////////
    // 一律条件・容器別条件リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setAllContainerTypeRender(             Boolean.FALSE );
    initRow.setAllCcActionFlRNRender(              Boolean.FALSE );
    initRow.setSelCcActionFlRNRender(              Boolean.FALSE );

    allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    while ( allCcRow != null )
    {
      allCcRow.setAllDiscountAmtReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm1BmRateReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm1BmAmountReadOnly(        Boolean.TRUE  );
      allCcRow.setAllCcBm2BmRateReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm2BmAmountReadOnly(        Boolean.TRUE  );
      allCcRow.setAllCcBm3BmRateReadOnly(          Boolean.TRUE  );
      allCcRow.setAllCcBm3BmAmountReadOnly(        Boolean.TRUE  );
      
      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }

    selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    while ( selCcRow != null )
    {
      selCcRow.setSelDiscountAmtReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm1BmRateReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm1BmAmountReadOnly(        Boolean.TRUE  );
      selCcRow.setSelCcBm2BmRateReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm2BmAmountReadOnly(        Boolean.TRUE  );
      selCcRow.setSelCcBm3BmRateReadOnly(          Boolean.TRUE  );
      selCcRow.setSelCcBm3BmAmountReadOnly(        Boolean.TRUE  );

      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }

    /////////////////////////////////////
    // その他条件リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setContractYearDateRender(             Boolean.FALSE );
    initRow.setInstallSupportAmtRender(            Boolean.FALSE );
    initRow.setInstallSupportAmt2Render(           Boolean.FALSE );
    initRow.setPaymentCycleRender(                 Boolean.FALSE );
    initRow.setElectricityTypeRender(              Boolean.FALSE );
    initRow.setElectricityAmountRender(            Boolean.FALSE );
    initRow.setConditionReasonRender(              Boolean.FALSE );
    
    /////////////////////////////////////
    // BM1リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setBm1SendTypeRender(                  Boolean.FALSE );
    initRow.setBm1VendorNumber1Render(             Boolean.FALSE );
    initRow.setBm1VendorNumber2Render(             Boolean.FALSE );
    initRow.setBm1VendorNameRender(                Boolean.FALSE );
    initRow.setBm1VendorNameAltRender(             Boolean.FALSE );
    initRow.setBm1PostCdFRender(                   Boolean.FALSE );
    initRow.setBm1PostCdSRender(                   Boolean.FALSE );
    initRow.setBm1StateRender(                     Boolean.FALSE );
    initRow.setBm1CityRender(                      Boolean.FALSE );
    initRow.setBm1Address1Render(                  Boolean.FALSE );
    initRow.setBm1Address2Render(                  Boolean.FALSE );
    initRow.setBm1AddressLineRender(               Boolean.FALSE );
    initRow.setBm1TransferTypeRender(              Boolean.FALSE );
    initRow.setBm1PaymentTypeRender(               Boolean.FALSE );

    /////////////////////////////////////
    // BM2リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setBm2VendorNumber1Render(             Boolean.FALSE );
    initRow.setBm2VendorNumber2Render(             Boolean.FALSE );
    initRow.setBm2VendorNameRender(                Boolean.FALSE );
    initRow.setBm2VendorNameAltRender(             Boolean.FALSE );
    initRow.setBm2PostCdFRender(                   Boolean.FALSE );
    initRow.setBm2PostCdSRender(                   Boolean.FALSE );
    initRow.setBm2StateRender(                     Boolean.FALSE );
    initRow.setBm2CityRender(                      Boolean.FALSE );
    initRow.setBm2Address1Render(                  Boolean.FALSE );
    initRow.setBm2Address2Render(                  Boolean.FALSE );
    initRow.setBm2AddressLineRender(               Boolean.FALSE );
    initRow.setBm2TransferTypeRender(              Boolean.FALSE );
    initRow.setBm2PaymentTypeRender(               Boolean.FALSE );

    /////////////////////////////////////
    // BM3リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setBm3VendorNumber1Render(             Boolean.FALSE );
    initRow.setBm3VendorNumber2Render(             Boolean.FALSE );
    initRow.setBm3VendorNameRender(                Boolean.FALSE );
    initRow.setBm3VendorNameAltRender(             Boolean.FALSE );
    initRow.setBm3PostCdFRender(                   Boolean.FALSE );
    initRow.setBm3PostCdSRender(                   Boolean.FALSE );
    initRow.setBm3StateRender(                     Boolean.FALSE );
    initRow.setBm3CityRender(                      Boolean.FALSE );
    initRow.setBm3Address1Render(                  Boolean.FALSE );
    initRow.setBm3Address2Render(                  Boolean.FALSE );
    initRow.setBm3AddressLineRender(               Boolean.FALSE );
    initRow.setBm3TransferTypeRender(              Boolean.FALSE );
    initRow.setBm3PaymentTypeRender(               Boolean.FALSE );

    /////////////////////////////////////
    // 契約書への記載事項リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setReflectContractButtonRender(        Boolean.FALSE );
    initRow.setOtherContentRender(                 Boolean.FALSE );

    /////////////////////////////////////
    // 概算年間損益リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setCalcProfitButtonRender(             Boolean.FALSE );
    initRow.setSalesMonthRender(                   Boolean.FALSE );
    initRow.setBmRateRender(                       Boolean.FALSE );
    initRow.setLeaseChargeMonthRender(             Boolean.FALSE );
    initRow.setConstructionChargeRender(           Boolean.FALSE );
    initRow.setElectricityAmtMonthRender(          Boolean.FALSE );

    /////////////////////////////////////
    // 添付リージョン
    /////////////////////////////////////
    // すべて入力不可
    initRow.setAttachActionFlRNRender(             Boolean.FALSE );

    attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    while ( attachRow != null )
    {
      attachRow.setExcerptReadOnly(                Boolean.TRUE  );
      attachRow.setAttachSelectionRender(          Boolean.FALSE );
      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }
  }


  /*****************************************************************************
   * 回送先リージョン表示属性プロパティ設定
   * @param initVo        SP専決初期化用ビューインスタンス
   * @param sendVo        回送先登録／更新用ビューインスタンス
   *****************************************************************************
   */
  private static void setSendRegionProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    
    /////////////////////////////////////
    // 回送先リージョン
    /////////////////////////////////////
    // 処理対象のユーザーのみ決裁コメントを入力可能
    // 処理対象のユーザー以降の範囲、従業員番号を入力可能
    boolean duringFlag = false;
    String applicationCode      = headerRow.getApplicationCode();
    String loginEmployeeNumber  = initRow.getEmployeeNumber();
    String status               = headerRow.getStatus();

    sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    while ( sendRow != null )
    {
/* 20090716_abe_0000385 START*/

      String approvalStateType    = sendRow.getApprovalStateType();

      // 決裁状態区分(0：未処理)
      if (XxcsoSpDecisionConstants.APPR_NONE.equals(approvalStateType))
      {
        // コメントを使用不可
        sendRow.setApprovalCommentReadOnly(      Boolean.TRUE  );
      }
      // 決裁状態区分(1：処理中)
      else if (XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType))
      {
        String targetEmployeeNumber = sendRow.getApproveCode();
        if ( loginEmployeeNumber.equals(targetEmployeeNumber) )
        {
          sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
          sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
        }
        else
        {
          sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
          sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
          sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );      
        }
        duringFlag = true;
      }
      // 決裁状態区分(2：処理済)
      else if (XxcsoSpDecisionConstants.APPR_END.equals(approvalStateType))
      {
        // 承認者、関連、コメントを使用不可
        sendRow.setRangeTypeReadOnly(            Boolean.TRUE  );
        sendRow.setApproveCodeReadOnly(          Boolean.TRUE  );
        sendRow.setApprovalCommentReadOnly(      Boolean.TRUE  );
      }

      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }
    

    sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    while ( sendRow != null )
    {
      // 回送先に決裁状態区分(1：処理中)が存在する場合
      if ( duringFlag)
      {

        String approvalStateType    = sendRow.getApprovalStateType();

        // 決裁状態区分(1：処理中)
        if (XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType))
        {
          break;
        }
        // 承認者、関連を使用不可
        sendRow.setRangeTypeReadOnly(            Boolean.TRUE  );
        sendRow.setApproveCodeReadOnly(          Boolean.TRUE  );
      }
      // 回送先に決裁状態区分(1：処理中)が存在しない場合
      else
      {
        if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
        {
          // ステータスが有効の場合は、すべて入力不可
          sendRow.setRangeTypeReadOnly(            Boolean.TRUE  );
          sendRow.setApproveCodeReadOnly(          Boolean.TRUE  );
          sendRow.setApprovalCommentReadOnly(      Boolean.TRUE  );
        }
      } 
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }

//      if ( applicationCode.equals(loginEmployeeNumber) )
//      {
//        // 承認コメント以外
//        // すべて入力可能
//        sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );
//
//        if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
//        {
//          // ステータスが有効の場合は、すべて入力不可
//          sendRow.setRangeTypeReadOnly(            Boolean.TRUE  );
//          sendRow.setApproveCodeReadOnly(          Boolean.TRUE  );
//        }
//        
//        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
//        continue;
//      }
//      
//      String targetEmployeeNumber = sendRow.getApproveCode();
//      String approvalStateType    = sendRow.getApprovalStateType();
//
//      if ( XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType) )
//      {
//        duringFlag = true;
//        
//        if ( loginEmployeeNumber.equals(targetEmployeeNumber) )
//        {
//          sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
//          sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
//        }
//        else
//        {
//          sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
//          sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
//          sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );        
//        }
//      }
//      else
//      {
//        sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );
//      }
//
//      if ( ! duringFlag )
//      {
//        // 承認作業中ユーザー以前のユーザーは入力不可
//        sendRow.setRangeTypeReadOnly(              Boolean.TRUE  );
//        sendRow.setApproveCodeReadOnly(            Boolean.TRUE  );
//        sendRow.setApprovalCommentReadOnly(        Boolean.TRUE  );        
//      }
//      
//      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
//    }
/* 20090716_abe_0000385 END*/

  }

  
  /*****************************************************************************
   * 表示属性プロパティ基本設定
   * @param initVo        SP専決初期化用ビューインスタンス
   * @param headerVo      SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo     設置先登録／更新用ビューインスタンス
   * @param cntrctVo      契約先登録／更新用ビューインスタンス
   * @param bm1Vo         BM1登録／更新用ビューインスタンス
   * @param bm2Vo         BM2登録／更新用ビューインスタンス
   * @param bm3Vo         BM3登録／更新用ビューインスタンス
   * @param sendVo        回送先登録／更新用ビューインスタンス
   *****************************************************************************
   */
  private static void setBaseProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionHeaderFullVOImpl      headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl    installVo
   ,XxcsoSpDecisionBm1CustFullVOImpl     bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl     bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl     bm3Vo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.first();
    XxcsoSpDecisionSendFullVORowImpl sendRow
      = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();

    /////////////////////////////////////
    //申請区分により、表示／非表示を設定
    /////////////////////////////////////
    String applicationType = headerRow.getApplicationType();
    if ( XxcsoSpDecisionConstants.APP_TYPE_NEW.equals(applicationType) )
    {
      initRow.setInstallDateRender(                  Boolean.FALSE );
      initRow.setInstallDateViewRender(              Boolean.FALSE );
    }
    else
    {
      initRow.setInstallDateRequiredRender(          Boolean.FALSE );
      initRow.setInstallDateRequiredViewRender(      Boolean.FALSE );
    }

    /////////////////////////////////////
    // 業態（小分類）により、表示／非表示を設定
    /////////////////////////////////////
    String bizCondType = installRow.getBusinessConditionType();
    if ( bizCondType == null || "".equals(bizCondType) )
    {
      initRow.setBm1InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
      initRow.setBm3InfoHdrRNRender(                 Boolean.FALSE );
    }
    
    if ( XxcsoSpDecisionConstants.BIZ_COND_OFF_SET_VD.equals(bizCondType) )
    {
      initRow.setBm1InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
      initRow.setBm3InfoHdrRNRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    //新台旧台区分により、表示／非表示を設定
    /////////////////////////////////////
    String newoldType = headerRow.getNewoldType();
    if ( XxcsoSpDecisionConstants.NEW_OLD_NEW.equals(newoldType) )
    {
      initRow.setVdInfo3LayoutRender(                Boolean.FALSE );
    }
    else
    {
      initRow.setVdInfo3RequiredLayoutRender(        Boolean.FALSE );
    }

    /////////////////////////////////////
    // 取引条件により、表示／非表示を設定
    /////////////////////////////////////
    String condBizType = headerRow.getConditionBusinessType();
    if ( condBizType == null || "".equals(condBizType) )
    {
      // 選択されていない場合は、ヘッダリージョンごと非表示
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_NON_PAY_BM.equals(condBizType) )
    {
      // BM支払なしの場合は、ヘッダリージョンごと非表示
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }
    
    if ( XxcsoSpDecisionConstants.COND_SALES.equals(condBizType) )
    {
      // 売価別条件の場合は、一律条件・容器別条件ヘッダごと非表示
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      // 寄付金を非表示
      initRow.setScContributeGrpRender(              Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_SALES_CONTRIBUTE.equals(condBizType) )
    {
      // 売価別条件（寄付金登録用）の場合は、一律条件・容器別条件ヘッダごと非表示
      initRow.setContainerConditionHdrRNRender(      Boolean.FALSE );
      // BM2を非表示
      initRow.setScBm2GrpRender(                     Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_CNTNR.equals(condBizType) )
    {
      // 一律条件・容器別条件の場合は、売価別条件ヘッダごと非表示
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      // 寄付金を非表示
      initRow.setAllCcContributeGrpRender(           Boolean.FALSE );
      initRow.setSelCcContributeGrpRender(           Boolean.FALSE );
      initRow.setContributeInfoHdrRNRender(          Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.COND_CNTNR_CONTRIBUTE.equals(condBizType) )
    {
      // 一律条件・容器別条件の場合は、売価別条件ヘッダごと非表示
      initRow.setSalesConditionHdrRNRender(          Boolean.FALSE );
      // BM2を非表示
      initRow.setAllCcBm2GrpRender(                  Boolean.FALSE );
      initRow.setSelCcBm2GrpRender(                  Boolean.FALSE );
      initRow.setBm2InfoHdrRNRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // 全容器区分により、表示／非表示を設定
    /////////////////////////////////////
    String allContainerType = headerRow.getAllContainerType();
    if ( XxcsoSpDecisionConstants.CNTNR_ALL.equals(allContainerType) )
    {
      // 全容器一律条件条件の場合は、容器別条件テーブルを非表示
      initRow.setSelCcAdvTblRNRender(                Boolean.FALSE );
    }
    else
    {
      // 容器別条件の場合は、全容器一律条件テーブルを非表示
      initRow.setAllCcAdvTblRNRender(                Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // 電気代区分により、表示／非表示を設定
    /////////////////////////////////////
    String elecType = headerRow.getElectricityType();
    if ( XxcsoSpDecisionConstants.ELEC_FIXED.equals(elecType)    ||
         XxcsoSpDecisionConstants.ELEC_VALIABLE.equals(elecType)
       )
    {
      initRow.setElecStartLabelRender(               Boolean.FALSE );
    }
    else
    {
      initRow.setElecStartRequiredLabelRender(       Boolean.FALSE );
      initRow.setElectricityAmountRender(            Boolean.FALSE );
      initRow.setElectricityAmountViewRender(        Boolean.FALSE );
      initRow.setElecAmountLabelRender(              Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // 支払条件・明細書（BM1）により、表示／非表示を設定
    /////////////////////////////////////
    String bm1PaymentType = bm1Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm1PaymentType) )
    {
      // 支払条件・明細書（BM1）が支払なしの場合は、
      // 支払条件・明細書（BM1）以外を非表示
      initRow.setBm1SendTypeRender(                  Boolean.FALSE );
      initRow.setBm1SendTypeViewRender(              Boolean.FALSE );
      initRow.setBm1VendorNumber1Render(             Boolean.FALSE );
      initRow.setBm1VendorNumber2Render(             Boolean.FALSE );
      initRow.setBm1VendorNumberViewRender(          Boolean.FALSE );
      initRow.setBm1VendorNameRender(                Boolean.FALSE );
      initRow.setBm1VendorNameViewRender(            Boolean.FALSE );
      initRow.setBm1VendorNameAltRender(             Boolean.FALSE );
      initRow.setBm1VendorNameAltViewRender(         Boolean.FALSE );
      initRow.setBm1PostalCodeLayoutRender(          Boolean.FALSE );
      initRow.setBm1StateRender(                     Boolean.FALSE );
      initRow.setBm1StateViewRender(                 Boolean.FALSE );
      initRow.setBm1CityRender(                      Boolean.FALSE );
      initRow.setBm1CityViewRender(                  Boolean.FALSE );
      initRow.setBm1Address1Render(                  Boolean.FALSE );
      initRow.setBm1Address1ViewRender(              Boolean.FALSE );
      initRow.setBm1Address2Render(                  Boolean.FALSE );
      initRow.setBm1Address2ViewRender(              Boolean.FALSE );
      initRow.setBm1AddressLineRender(               Boolean.FALSE );
      initRow.setBm1AddressLineViewRender(           Boolean.FALSE );
      initRow.setBm1TransferTypeLayoutRender(        Boolean.FALSE );
      initRow.setBm1InquiryBaseLayoutRender(         Boolean.FALSE );
    }

    /////////////////////////////////////
    // 支払条件・明細書（BM2）により、表示／非表示を設定
    /////////////////////////////////////
    String bm2PaymentType = bm2Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm2PaymentType) )
    {
      // 支払条件・明細書（BM2）が支払なしの場合は、
      // 支払条件・明細書（BM2）以外を非表示
      initRow.setBm2VendorNumber1Render(             Boolean.FALSE );
      initRow.setBm2VendorNumber2Render(             Boolean.FALSE );
      initRow.setBm2VendorNumberViewRender(          Boolean.FALSE );
      initRow.setBm2VendorNameRender(                Boolean.FALSE );
      initRow.setBm2VendorNameViewRender(            Boolean.FALSE );
      initRow.setBm2VendorNameAltRender(             Boolean.FALSE );
      initRow.setBm2VendorNameAltViewRender(         Boolean.FALSE );
      initRow.setBm2PostalCodeLayoutRender(          Boolean.FALSE );
      initRow.setBm2StateRender(                     Boolean.FALSE );
      initRow.setBm2StateViewRender(                 Boolean.FALSE );
      initRow.setBm2CityRender(                      Boolean.FALSE );
      initRow.setBm2CityViewRender(                  Boolean.FALSE );
      initRow.setBm2Address1Render(                  Boolean.FALSE );
      initRow.setBm2Address1ViewRender(              Boolean.FALSE );
      initRow.setBm2Address2Render(                  Boolean.FALSE );
      initRow.setBm2Address2ViewRender(              Boolean.FALSE );
      initRow.setBm2AddressLineRender(               Boolean.FALSE );
      initRow.setBm2AddressLineViewRender(           Boolean.FALSE );
      initRow.setBm2TransferTypeLayoutRender(        Boolean.FALSE );
      initRow.setBm2InquiryBaseLayoutRender(         Boolean.FALSE );
    }

    /////////////////////////////////////
    // 支払条件・明細書（BM3）により、表示／非表示を設定
    /////////////////////////////////////
    String bm3PaymentType = bm3Row.getBmPaymentType();
    if ( XxcsoSpDecisionConstants.PAYMENT_TYPE_NONE.equals(bm3PaymentType) )
    {
      // 支払条件・明細書（BM3）が支払なしの場合は、
      // 支払条件・明細書（BM3）以外を非表示
      initRow.setBm3VendorNumber1Render(             Boolean.FALSE );
      initRow.setBm3VendorNumber2Render(             Boolean.FALSE );
      initRow.setBm3VendorNumberViewRender(          Boolean.FALSE );
      initRow.setBm3VendorNameRender(                Boolean.FALSE );
      initRow.setBm3VendorNameViewRender(            Boolean.FALSE );
      initRow.setBm3VendorNameAltRender(             Boolean.FALSE );
      initRow.setBm3VendorNameAltViewRender(         Boolean.FALSE );
      initRow.setBm3PostalCodeLayoutRender(          Boolean.FALSE );
      initRow.setBm3StateRender(                     Boolean.FALSE );
      initRow.setBm3StateViewRender(                 Boolean.FALSE );
      initRow.setBm3CityRender(                      Boolean.FALSE );
      initRow.setBm3CityViewRender(                  Boolean.FALSE );
      initRow.setBm3Address1Render(                  Boolean.FALSE );
      initRow.setBm3Address1ViewRender(              Boolean.FALSE );
      initRow.setBm3Address2Render(                  Boolean.FALSE );
      initRow.setBm3Address2ViewRender(              Boolean.FALSE );
      initRow.setBm3AddressLineRender(               Boolean.FALSE );
      initRow.setBm3AddressLineViewRender(           Boolean.FALSE );
      initRow.setBm3TransferTypeLayoutRender(        Boolean.FALSE );
      initRow.setBm3InquiryBaseLayoutRender(         Boolean.FALSE );
    }

    /////////////////////////////////////
    // 電気代のスペーサの表示／非表示を設定
    /////////////////////////////////////
    String cntrctElecAmtView = headerRow.getElectricityAmountView();
    if ( cntrctElecAmtView == null || "".equals(cntrctElecAmtView) )
    {
      initRow.setCntrctElecSpacer2Render(            Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // ボタンの表示／非表示を設定
    /////////////////////////////////////
    boolean firstFlag   = false;
    boolean submitFlag  = true;
    boolean confirmFlag = false;
    boolean approveFlag = false;
    String loginEmployeeNumber = initRow.getEmployeeNumber();
// 2009-04-20 [ST障害T1_0302] Add Start
    boolean contReturnSelfFlag = false;
// 2009-04-20 [ST障害T1_0302] Add End
    while ( sendRow != null )
    {
      String approveCode = sendRow.getApproveCode();
      if ( XxcsoSpDecisionConstants.INIT_APPROVE_CODE.equals(approveCode) )
      {
        sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
        continue;
      }

      String approvalStateType = sendRow.getApprovalStateType();
      if ( ! firstFlag )
      {
        firstFlag = true;
        if ( ! XxcsoSpDecisionConstants.APPR_NONE.equals(approvalStateType) )
        {
          submitFlag = false;
        }
      }

      if ( XxcsoSpDecisionConstants.APPR_DURING.equals(approvalStateType) )
      {
        if ( approveCode.equals(loginEmployeeNumber) )
        {
          String workRequestType = sendRow.getWorkRequestType();
          if ( XxcsoSpDecisionConstants.REQ_APPROVE.equals(workRequestType) )
          {
            approveFlag = true;
          }
          else
          {
            confirmFlag = true;
          }
        }
      }
// 2009-07-16 [障害0000385] Mod Start
// 2009-04-20 [ST障害T1_0302] Add Start
//      String approvalContent = sendRow.getApprovalContent();
//      if ( XxcsoSpDecisionConstants.APPR_CONT_RETURN.equals( approvalContent ) )
//      {
//        if ( approveCode.equals( loginEmployeeNumber ) )
//        {
//          contReturnSelfFlag = true;
//        }
//// 2009-05-13 [ST障害T1_0954] Del Start
////        else
////        {
////          contReturnSelfFlag = false;
////        }
//// 2009-05-13 [ST障害T1_0954] Del End
//      }
//// 2009-04-20 [ST障害T1_0302] Add End
// 2009-07-16 [障害0000385] Mod End
      
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }
    
    /////////////////////////////////////
    // 適用ボタンの表示／非表示を設定
    /////////////////////////////////////
    String appBaseCode = headerRow.getAppBaseCode();
    String loginBaseCode = initRow.getBaseCode();
// 2009-08-04 [障害0000820] Add Start
    String applicationCode = headerRow.getApplicationCode();
// 2009-08-04 [障害0000820] Add End
    if ( appBaseCode   == null               ||
         loginBaseCode == null               ||
         ! appBaseCode.equals(loginBaseCode)
       )
    {
// 2009-08-04 [障害0000820] Add Start
      if ( ! loginEmployeeNumber.equals(applicationCode) )
      {
        // 拠点コードが一致しない場合、かつ、
        // 申請者がログインユーザーでない場合は
        // 適用ボタンを非表示
// 2009-08-04 [障害0000820] Add End    
        // 拠点コードが一致しない場合は、適用ボタンを非表示
        initRow.setApplyButtonRender(                  Boolean.FALSE );
// 2009-08-04 [障害0000820] Add Start
      }
// 2009-08-04 [障害0000820] Add End
    }

    String status = headerRow.getStatus();
    if ( ! XxcsoSpDecisionConstants.STATUS_INPUT.equals(status) )
    {
      // ステータスが入力中以外の場合は、適用ボタンを非表示
      initRow.setApplyButtonRender(                  Boolean.FALSE );
    }

    /////////////////////////////////////
    // 提出ボタンの表示／非表示を設定
    /////////////////////////////////////
    if ( appBaseCode   == null               ||
         loginBaseCode == null               ||
         ! appBaseCode.equals(loginBaseCode)
       )
    {
// 2009-08-04 [障害0000820] Add Start
      if ( ! loginEmployeeNumber.equals(applicationCode) )
      {
        // 拠点コードが一致しない場合、かつ、
        // 申請者がログインユーザーでない場合は
        // 提出ボタンを非表示
// 2009-08-04 [障害0000820] Add End    
        // 拠点コードが一致しない場合は、提出ボタンを非表示
        initRow.setSubmitButtonRender(                 Boolean.FALSE );
// 2009-08-04 [障害0000820] Add Start
      }
// 2009-08-04 [障害0000820] Add End
    }

    if ( ! submitFlag )
    {
      // SP専決回送内の最初の承認階層に紐づくSP専決回送先の
      // 決裁状態が「未処理」でない場合は、提出ボタンを非表示
      initRow.setSubmitButtonRender(                 Boolean.FALSE );
    }
    
    if ( ! XxcsoSpDecisionConstants.STATUS_INPUT.equals(status) &&
         ! XxcsoSpDecisionConstants.STATUS_REJECT.equals(status)
       )
    {
      // ステータスが入力中、否決以外の場合は、提出ボタンを非表示
      initRow.setSubmitButtonRender(                 Boolean.FALSE );
    }

// 2009-07-16 [障害0000385] Mod Start
//// 2009-04-20 [ST障害T1_0302] Add Start
//    if ( contReturnSelfFlag )
//    {
//      // 決裁内容が返却の場合は提出ボタンを非表示
//      initRow.setSubmitButtonRender(                 Boolean.FALSE );
//    }
//// 2009-04-20 [ST障害T1_0302] Add End
// 2009-07-16 [障害0000385] Mod End

    /////////////////////////////////////
    // 確認ボタン、返却ボタンの表示／非表示を設定
    /////////////////////////////////////
    if ( ! confirmFlag )
    {
      // 決裁状態区分が処理中でない場合は、
      // 確認ボタン、返却ボタンを非表示
      initRow.setConfirmButtonRender(                Boolean.FALSE );
      initRow.setReturnButtonRender(                 Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
    {
      // ステータスが有効の場合は、
      // 返却ボタンを非表示
      initRow.setReturnButtonRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // 承認ボタン、否決ボタンの表示／非表示を設定
    /////////////////////////////////////
    if ( ! approveFlag )
    {
      // 決裁状態区分が処理中でない場合は、
      // 承認ボタン、否決ボタンを非表示
      initRow.setApproveButtonRender(                Boolean.FALSE );
      initRow.setRejectButtonRender(                 Boolean.FALSE );
    }

    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
    {
      // ステータスが有効の場合は、
      // 否決ボタンを非表示
      initRow.setRejectButtonRender(                 Boolean.FALSE );
    }
    
    /////////////////////////////////////
    // 発注依頼ボタンの表示／非表示を設定
    /////////////////////////////////////
    String publishBaseCode = installRow.getPublishBaseCode();
    boolean requestEnabledFlag = false;
    // 2011-04-25 [E_本稼動_07224] Add Start
    // 発注依頼のみ可能な発注代行拠点取得
    String actpobase_code  = initRow.getActPoBaseCode();
    // 2011-04-25 [E_本稼動_07224] Add End
    
    if ( XxcsoSpDecisionConstants.STATUS_ENABLE.equals(status) )
    {
      if ( loginBaseCode != null )
      {
        if ( loginBaseCode.equals(appBaseCode) )
        {
          // ステータスが有効で、
          // ログインユーザーの拠点コードと申請拠点が同じ場合は、
          // 発注依頼ボタンは表示
          requestEnabledFlag = true;
        }

        if ( loginBaseCode.equals(publishBaseCode) )
        {
          // ステータスが有効で、
          // ログインユーザーの拠点コードと担当拠点が同じ場合は、
          // 発注依頼ボタンは表示
          requestEnabledFlag = true;
        }
        // 2011-04-25 [E_本稼動_07224] Add Start
        if ( loginBaseCode.equals(actpobase_code) )
        {
          // ステータスが有効で、
          // ログインユーザーの拠点コードと発注代行拠点が同じ場合は、
          // 発注依頼ボタンは表示
          requestEnabledFlag = true;
        }
        // 2011-04-25 [E_本稼動_07224] Add End
      }
    }

    if ( ! requestEnabledFlag )
    {
      initRow.setRequestButtonRender(                Boolean.FALSE );
    }
  }



  
  /*****************************************************************************
   * 表示属性プロパティ初期化
   * @param initVo        SP専決初期化用ビューインスタンス
   * @param scVo          売価別条件登録／更新用ビューインスタンス
   * @param allCcVo       全容器一律登録／更新用ビューインスタンス
   * @param selCcVo       容器別条件登録／更新用ビューインスタンス
   * @param attachVo      添付登録／更新用ビューインスタンス
   * @param sendVo        回送先登録／更新用ビューインスタンス
   *****************************************************************************
   */
  private static void initializeProperty(
    XxcsoSpDecisionInitVOImpl            initVo
   ,XxcsoSpDecisionScLineFullVOImpl      scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl   allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl   selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl      attachVo
   ,XxcsoSpDecisionSendFullVOImpl        sendVo
  )
  {
    /////////////////////////////////////
    // 各行を取得
    /////////////////////////////////////
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
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

    /////////////////////////////////////
    // 初期化
    /////////////////////////////////////
      // 基本情報リージョン
    initRow.setApplicationTypeRender(            Boolean.TRUE  );
    initRow.setApplicationTypeViewRender(        Boolean.TRUE  );
    
      // 設置先情報リージョン
    initRow.setInstallAcctNumber1Render(         Boolean.TRUE  );
    initRow.setInstallAcctNumber2Render(         Boolean.TRUE  );
    initRow.setInstallAcctNumberViewRender(      Boolean.TRUE  );
    initRow.setInstallPartyNameRender(           Boolean.TRUE  );
    initRow.setInstallPartyNameViewRender(       Boolean.TRUE  );
    initRow.setInstallPartyNameAltRender(        Boolean.TRUE  );
    initRow.setInstallPartyNameAltViewRender(    Boolean.TRUE  );
    initRow.setInstallNameRender(                Boolean.TRUE  );
    initRow.setInstallNameViewRender(            Boolean.TRUE  );
    initRow.setInstallPostCdFRender(             Boolean.TRUE  );
    initRow.setInstallPostCdFViewRender(         Boolean.TRUE  );
    initRow.setInstallPostCdSRender(             Boolean.TRUE  );
    initRow.setInstallPostCdSViewRender(         Boolean.TRUE  );
    initRow.setInstallStateRender(               Boolean.TRUE  );
    initRow.setInstallStateViewRender(           Boolean.TRUE  );
    initRow.setInstallCityRender(                Boolean.TRUE  );
    initRow.setInstallCityViewRender(            Boolean.TRUE  );
    initRow.setInstallAddress1Render(            Boolean.TRUE  );
    initRow.setInstallAddress1ViewRender(        Boolean.TRUE  );
    initRow.setInstallAddress2Render(            Boolean.TRUE  );
    initRow.setInstallAddress2ViewRender(        Boolean.TRUE  );
    initRow.setInstallAddressLineRender(         Boolean.TRUE  );
    initRow.setInstallAddressLineViewRender(     Boolean.TRUE  );
    initRow.setBizCondTypeRender(                Boolean.TRUE  );
    initRow.setBizCondTypeViewRender(            Boolean.TRUE  );
    initRow.setBusinessTypeRender(               Boolean.TRUE  );
    initRow.setBusinessTypeViewRender(           Boolean.TRUE  );
    initRow.setInstallLocationRender(            Boolean.TRUE  );
    initRow.setInstallLocationViewRender(        Boolean.TRUE  );
    initRow.setExtRefOpclTypeRender(             Boolean.TRUE  );
    initRow.setExtRefOpclTypeViewRender(         Boolean.TRUE  );
    initRow.setEmployeeNumberRender(             Boolean.TRUE  );
    initRow.setEmployeeNumberViewRender(         Boolean.TRUE  );
    initRow.setPublishBaseCodeRender(            Boolean.TRUE  );
    initRow.setPublishBaseCodeViewRender(        Boolean.TRUE  );
    initRow.setInstallDateRequiredRender(        Boolean.TRUE  );
    initRow.setInstallDateRequiredViewRender(    Boolean.TRUE  );
    initRow.setInstallDateRender(                Boolean.TRUE  );
    initRow.setInstallDateViewRender(            Boolean.TRUE  );
    initRow.setLeaseCompanyRender(               Boolean.TRUE  );
    initRow.setLeaseCompanyViewRender(           Boolean.TRUE  );

    // 契約先リージョン
    initRow.setSameInstallAcctFlagRender(        Boolean.TRUE  );
    initRow.setSameInstallAcctFlagViewRender(    Boolean.TRUE  );
    initRow.setContractNumber1Render(            Boolean.TRUE  );
    initRow.setContractNumber2Render(            Boolean.TRUE  );
    initRow.setContractNumberViewRender(         Boolean.TRUE  );
    initRow.setContractNameRender(               Boolean.TRUE  );
    initRow.setContractNameViewRender(           Boolean.TRUE  );
    initRow.setContractNameAltRender(            Boolean.TRUE  );
    initRow.setContractNameAltViewRender(        Boolean.TRUE  );
    initRow.setContractPostCdFRender(            Boolean.TRUE  );
    initRow.setContractPostCdFViewRender(        Boolean.TRUE  );
    initRow.setContractPostCdSRender(            Boolean.TRUE  );
    initRow.setContractPostCdSViewRender(        Boolean.TRUE  );
    initRow.setContractStateRender(              Boolean.TRUE  );
    initRow.setContractStateViewRender(          Boolean.TRUE  );
    initRow.setContractCityRender(               Boolean.TRUE  );
    initRow.setContractCityViewRender(           Boolean.TRUE  );
    initRow.setContractAddress1Render(           Boolean.TRUE  );
    initRow.setContractAddress1ViewRender(       Boolean.TRUE  );
    initRow.setContractAddress2Render(           Boolean.TRUE  );
    initRow.setContractAddress2ViewRender(       Boolean.TRUE  );
    initRow.setContractAddressLineRender(        Boolean.TRUE  );
    initRow.setContractAddressLineViewRender(    Boolean.TRUE  );
    initRow.setDelegateNameRender(               Boolean.TRUE  );
    initRow.setDelegateNameViewRender(           Boolean.TRUE  );

    // VD情報リージョン
    initRow.setNewoldTypeRender(                 Boolean.TRUE  );
    initRow.setNewoldTypeViewRender(             Boolean.TRUE  );
    initRow.setSeleNumberRender(                 Boolean.TRUE  );
    initRow.setSeleNumberViewRender(             Boolean.TRUE  );
    initRow.setMakerCodeRender(                  Boolean.TRUE  );
    initRow.setMakerCodeViewRender(              Boolean.TRUE  );
    initRow.setStandardTypeRender(               Boolean.TRUE  );
    initRow.setStandardTypeViewRender(           Boolean.TRUE  );
    initRow.setVdInfo3LayoutRender(              Boolean.TRUE  );
    initRow.setVdInfo3RequiredLayoutRender(      Boolean.TRUE  );
    initRow.setUnNumberRender(                   Boolean.TRUE  );
    initRow.setUnNumberViewRender(               Boolean.TRUE  );

    // 取引条件選択リージョン
    initRow.setCondBizTypeRender(                Boolean.TRUE  );
    initRow.setCondBizTypeViewRender(            Boolean.TRUE  );

    // 売価別条件リージョン
    initRow.setSalesConditionHdrRNRender(        Boolean.TRUE  );
    initRow.setScActionFlRNRender(               Boolean.TRUE  );
    initRow.setScTableFooterRender(              Boolean.TRUE  );
    initRow.setScBm2GrpRender(                   Boolean.TRUE  );
    initRow.setScContributeGrpRender(            Boolean.TRUE  );
    
    scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.first();
    while ( scRow != null )
    {
      scRow.setScMultipleSelectionRender(        Boolean.TRUE  );
      scRow.setFixedPriceReadOnly(               Boolean.FALSE );
      scRow.setSalesPriceReadOnly(               Boolean.FALSE );
      scRow.setScBm1BmRateReadOnly(              Boolean.FALSE );
      scRow.setScBm1BmAmountReadOnly(            Boolean.FALSE );
      scRow.setScBm2BmRateReadOnly(              Boolean.FALSE );
      scRow.setScBm2BmAmountReadOnly(            Boolean.FALSE );
      scRow.setScBm3BmRateReadOnly(              Boolean.FALSE );
      scRow.setScBm3BmAmountReadOnly(            Boolean.FALSE );
      
      scRow = (XxcsoSpDecisionScLineFullVORowImpl)scVo.next();
    }

    // 一律条件・容器別条件リージョン
    initRow.setContainerConditionHdrRNRender(    Boolean.TRUE  );
    initRow.setAllContainerTypeRender(           Boolean.TRUE  );
    initRow.setAllContainerTypeViewRender(       Boolean.TRUE  );
    
    // 一律条件・容器別条件リージョン（全容器）
    initRow.setAllCcAdvTblRNRender(              Boolean.TRUE  );
    initRow.setAllCcActionFlRNRender(            Boolean.TRUE  );
    initRow.setAllCcBm2GrpRender(                Boolean.TRUE  );
    initRow.setAllCcContributeGrpRender(         Boolean.TRUE  );

    allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.first();
    while ( allCcRow != null )
    {
      allCcRow.setAllDiscountAmtReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm1BmRateReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm1BmAmountReadOnly(      Boolean.FALSE );
      allCcRow.setAllCcBm2BmRateReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm2BmAmountReadOnly(      Boolean.FALSE );
      allCcRow.setAllCcBm3BmRateReadOnly(        Boolean.FALSE );
      allCcRow.setAllCcBm3BmAmountReadOnly(      Boolean.FALSE );

      allCcRow = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.next();
    }

    // 一律条件・容器別条件リージョン（全容器以外）
    initRow.setSelCcAdvTblRNRender(              Boolean.TRUE  );
    initRow.setSelCcActionFlRNRender(            Boolean.TRUE  );
    initRow.setSelCcBm2GrpRender(                Boolean.TRUE  );
    initRow.setSelCcContributeGrpRender(         Boolean.TRUE  );

    selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.first();
    while ( selCcRow != null )
    {
      selCcRow.setSelDiscountAmtReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm1BmRateReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm1BmAmountReadOnly(      Boolean.FALSE );
      selCcRow.setSelCcBm2BmRateReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm2BmAmountReadOnly(      Boolean.FALSE );
      selCcRow.setSelCcBm3BmRateReadOnly(        Boolean.FALSE );
      selCcRow.setSelCcBm3BmAmountReadOnly(      Boolean.FALSE );

      selCcRow = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.next();
    }

    // その他条件リージョン
    initRow.setContractYearDateRender(           Boolean.TRUE  );
    initRow.setContractYearDateViewRender(       Boolean.TRUE  );
    initRow.setInstallSupportAmtRender(          Boolean.TRUE  );
    initRow.setInstallSupportAmtViewRender(      Boolean.TRUE  );
    initRow.setInstallSupportAmt2Render(         Boolean.TRUE  );
    initRow.setInstallSupportAmt2ViewRender(     Boolean.TRUE  );
    initRow.setPaymentCycleRender(               Boolean.TRUE  );
    initRow.setPaymentCycleViewRender(           Boolean.TRUE  );
    initRow.setElecStartLabelRender(             Boolean.TRUE  );
    initRow.setElecStartRequiredLabelRender(     Boolean.TRUE  );
    initRow.setElectricityTypeRender(            Boolean.TRUE  );
    initRow.setElectricityTypeViewRender(        Boolean.TRUE  );
    initRow.setElectricityAmountRender(          Boolean.TRUE  );
    initRow.setElectricityAmountViewRender(      Boolean.TRUE  );
    initRow.setElecAmountLabelRender(            Boolean.TRUE  );
    initRow.setConditionReasonRender(            Boolean.TRUE  );
    initRow.setConditionReasonViewRender(        Boolean.TRUE  );

    // BM1リージョン
    initRow.setBm1InfoHdrRNRender(               Boolean.TRUE  );
    initRow.setBm1SendTypeRender(                Boolean.TRUE  );
    initRow.setBm1SendTypeViewRender(            Boolean.TRUE  );
    initRow.setBm1VendorNumber1Render(           Boolean.TRUE  );
    initRow.setBm1VendorNumber2Render(           Boolean.TRUE  );
    initRow.setBm1VendorNumberViewRender(        Boolean.TRUE  );
    initRow.setBm1VendorNameRender(              Boolean.TRUE  );
    initRow.setBm1VendorNameViewRender(          Boolean.TRUE  );
    initRow.setBm1VendorNameAltRender(           Boolean.TRUE  );
    initRow.setBm1VendorNameAltViewRender(       Boolean.TRUE  );
    initRow.setBm1TransferTypeLayoutRender(      Boolean.TRUE  );
    initRow.setBm1TransferTypeRender(            Boolean.TRUE  );
    initRow.setBm1TransferTypeViewRender(        Boolean.TRUE  );
    initRow.setBm1PaymentTypeRender(             Boolean.TRUE  );
    initRow.setBm1PaymentTypeViewRender(         Boolean.TRUE  );
    initRow.setBm1InquiryBaseLayoutRender(       Boolean.TRUE  );
    initRow.setBm1PostalCodeLayoutRender(        Boolean.TRUE  );
    initRow.setBm1PostCdFRender(                 Boolean.TRUE  );
    initRow.setBm1PostCdFViewRender(             Boolean.TRUE  );
    initRow.setBm1PostCdSRender(                 Boolean.TRUE  );
    initRow.setBm1PostCdSViewRender(             Boolean.TRUE  );
    // 2009-10-14 [IE554,IE573] Add Start
    //initRow.setBm1StateRender(                   Boolean.TRUE  );
    //initRow.setBm1StateViewRender(               Boolean.TRUE  );
    //initRow.setBm1CityRender(                    Boolean.TRUE  );
    //initRow.setBm1CityViewRender(                Boolean.TRUE  );
    initRow.setBm1StateRender(                   Boolean.FALSE  );
    initRow.setBm1StateViewRender(               Boolean.FALSE  );
    initRow.setBm1CityRender(                    Boolean.FALSE  );
    initRow.setBm1CityViewRender(                Boolean.FALSE  );
    // 2009-10-14 [IE554,IE573] Add End
    initRow.setBm1Address1Render(                Boolean.TRUE  );
    initRow.setBm1Address1ViewRender(            Boolean.TRUE  );
    initRow.setBm1Address2Render(                Boolean.TRUE  );
    initRow.setBm1Address2ViewRender(            Boolean.TRUE  );
    initRow.setBm1AddressLineRender(             Boolean.TRUE  );
    initRow.setBm1AddressLineViewRender(         Boolean.TRUE  );

    // BM2リージョン
    initRow.setBm2InfoHdrRNRender(               Boolean.TRUE  );
    initRow.setContributeInfoHdrRNRender(        Boolean.TRUE  );
    initRow.setBm2VendorNumber1Render(           Boolean.TRUE  );
    initRow.setBm2VendorNumber2Render(           Boolean.TRUE  );
    initRow.setBm2VendorNumberViewRender(        Boolean.TRUE  );
    initRow.setBm2VendorNameRender(              Boolean.TRUE  );
    initRow.setBm2VendorNameViewRender(          Boolean.TRUE  );
    initRow.setBm2VendorNameAltRender(           Boolean.TRUE  );
    initRow.setBm2VendorNameAltViewRender(       Boolean.TRUE  );
    initRow.setBm2PostalCodeLayoutRender(        Boolean.TRUE  );
    initRow.setBm2PostCdFRender(                 Boolean.TRUE  );
    initRow.setBm2PostCdFViewRender(             Boolean.TRUE  );
    initRow.setBm2PostCdSRender(                 Boolean.TRUE  );
    initRow.setBm2PostCdSViewRender(             Boolean.TRUE  );
    // 2009-10-14 [IE554,IE573] Add Start
    //initRow.setBm2StateRender(                   Boolean.TRUE  );
    //initRow.setBm2StateViewRender(               Boolean.TRUE  );
    //initRow.setBm2CityRender(                    Boolean.TRUE  );
    //initRow.setBm2CityViewRender(                Boolean.TRUE  );
    initRow.setBm2StateRender(                   Boolean.FALSE  );
    initRow.setBm2StateViewRender(               Boolean.FALSE  );
    initRow.setBm2CityRender(                    Boolean.FALSE  );
    initRow.setBm2CityViewRender(                Boolean.FALSE  );
    // 2009-10-14 [IE554,IE573] Add End
    initRow.setBm2Address1Render(                Boolean.TRUE  );
    initRow.setBm2Address1ViewRender(            Boolean.TRUE  );
    initRow.setBm2Address2Render(                Boolean.TRUE  );
    initRow.setBm2Address2ViewRender(            Boolean.TRUE  );
    initRow.setBm2AddressLineRender(             Boolean.TRUE  );
    initRow.setBm2AddressLineViewRender(         Boolean.TRUE  );
    initRow.setBm2TransferTypeLayoutRender(      Boolean.TRUE  );
    initRow.setBm2TransferTypeRender(            Boolean.TRUE  );
    initRow.setBm2TransferTypeViewRender(        Boolean.TRUE  );
    initRow.setBm2PaymentTypeRender(             Boolean.TRUE  );
    initRow.setBm2PaymentTypeViewRender(         Boolean.TRUE  );
    initRow.setBm2InquiryBaseLayoutRender(       Boolean.TRUE  );

    // BM3リージョン
    initRow.setBm3InfoHdrRNRender(               Boolean.TRUE  );
    initRow.setBm3VendorNumber1Render(           Boolean.TRUE  );
    initRow.setBm3VendorNumber2Render(           Boolean.TRUE  );
    initRow.setBm3VendorNumberViewRender(        Boolean.TRUE  );
    initRow.setBm3VendorNameRender(              Boolean.TRUE  );
    initRow.setBm3VendorNameViewRender(          Boolean.TRUE  );
    initRow.setBm3VendorNameAltRender(           Boolean.TRUE  );
    initRow.setBm3VendorNameAltViewRender(       Boolean.TRUE  );
    initRow.setBm3PostalCodeLayoutRender(        Boolean.TRUE  );
    initRow.setBm3PostCdFRender(                 Boolean.TRUE  );
    initRow.setBm3PostCdFViewRender(             Boolean.TRUE  );
    initRow.setBm3PostCdSRender(                 Boolean.TRUE  );
    initRow.setBm3PostCdSViewRender(             Boolean.TRUE  );
    // 2009-10-14 [IE554,IE573] Add Start
    //initRow.setBm3StateRender(                   Boolean.TRUE  );
    //initRow.setBm3StateViewRender(               Boolean.TRUE  );
    //initRow.setBm3CityRender(                    Boolean.TRUE  );
    //initRow.setBm3CityViewRender(                Boolean.TRUE  );
    initRow.setBm3StateRender(                   Boolean.FALSE  );
    initRow.setBm3StateViewRender(               Boolean.FALSE  );
    initRow.setBm3CityRender(                    Boolean.FALSE  );
    initRow.setBm3CityViewRender(                Boolean.FALSE  );
    // 2009-10-14 [IE554,IE573] Add End
    initRow.setBm3Address1Render(                Boolean.TRUE  );
    initRow.setBm3Address1ViewRender(            Boolean.TRUE  );
    initRow.setBm3Address2Render(                Boolean.TRUE  );
    initRow.setBm3Address2ViewRender(            Boolean.TRUE  );
    initRow.setBm3AddressLineRender(             Boolean.TRUE  );
    initRow.setBm3AddressLineViewRender(         Boolean.TRUE  );
    initRow.setBm3TransferTypeLayoutRender(      Boolean.TRUE  );
    initRow.setBm3TransferTypeRender(            Boolean.TRUE  );
    initRow.setBm3TransferTypeViewRender(        Boolean.TRUE  );
    initRow.setBm3PaymentTypeRender(             Boolean.TRUE  );
    initRow.setBm3PaymentTypeViewRender(         Boolean.TRUE  );
    initRow.setBm3InquiryBaseLayoutRender(       Boolean.TRUE  );

    // 契約書への記載事項リージョン
    initRow.setReflectContractButtonRender(      Boolean.TRUE  );
    initRow.setCntrctElecSpacer2Render(          Boolean.TRUE  );
    initRow.setOtherContentRender(               Boolean.TRUE  );
    initRow.setOtherContentViewRender(           Boolean.TRUE  );

    // 概算年間損益リージョン
    initRow.setCalcProfitButtonRender(           Boolean.TRUE  );
    initRow.setSalesMonthRender(                 Boolean.TRUE  );
    initRow.setSalesMonthViewRender(             Boolean.TRUE  );
    initRow.setBmRateRender(                     Boolean.TRUE  );
    initRow.setBmRateViewRender(                 Boolean.TRUE  );
    initRow.setLeaseChargeMonthRender(           Boolean.TRUE  );
    initRow.setLeaseChargeMonthViewRender(       Boolean.TRUE  );
    initRow.setConstructionChargeRender(         Boolean.TRUE  );
    initRow.setConstructionChargeViewRender(     Boolean.TRUE  );
    initRow.setElectricityAmtMonthRender(        Boolean.TRUE  );
    initRow.setElectricityAmtMonthViewRender(    Boolean.TRUE  );

    // 添付リージョン
    initRow.setAttachActionFlRNRender(           Boolean.TRUE  );

    attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.first();
    while ( attachRow != null )
    {
      attachRow.setExcerptReadOnly(              Boolean.FALSE );
      
      attachRow = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.next();
    }
    
    // 回送先リージョン
    sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.first();
    while ( sendRow != null )
    {
      sendRow.setRangeTypeReadOnly(              Boolean.FALSE );
      sendRow.setApprovalCommentReadOnly(        Boolean.FALSE );
      sendRow.setApprovalCommentReadOnly(        Boolean.FALSE );
      
      sendRow = (XxcsoSpDecisionSendFullVORowImpl)sendVo.next();
    }

    // ボタン
    initRow.setApplyButtonRender(                Boolean.TRUE  );
    initRow.setSubmitButtonRender(               Boolean.TRUE  );
    initRow.setRejectButtonRender(               Boolean.TRUE  );
    initRow.setApproveButtonRender(              Boolean.TRUE  );
    initRow.setReturnButtonRender(               Boolean.TRUE  );
    initRow.setConfirmButtonRender(              Boolean.TRUE  );
    initRow.setRequestButtonRender(              Boolean.TRUE  );
  }
}