/*============================================================================
* ファイル名 : XxcsoContractRegistInitUtils
* 概要説明   : 自販機設置契約情報登録初期ユーティリティクラス
* バージョン : 1.4
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-27 1.0  SCS小川浩    新規作成
* 2009-02-16 1.1  SCS柳平直人  [CT1-007]送付先コード初期値設定漏れ対応
* 2009-02-19 1.1  SCS柳平直人  [CT1-016]基本情報リージョン値設定漏れ対応
* 2009-02-23 1.1  SCS柳平直人  [CT1-021]送付先コード取得不正対応
*                              [CT1-022]口座情報取得不正対応
* 2009-02-25 1.1  SCS柳平直人  [CT1-029]コピー時送付先テーブルデータ不正対応
* 2009-05-25 1.2  SCS柳平直人  [ST障害T1_1136]LOVPK項目設定対応
* 2015-02-02 1.3  SCSK山下翔太 [E_本稼動_12565]SP専決・契約書画面改修
* 2015-11-26 1.4  SCSK山下翔太 [E_本稼動_13345]オーナ変更マスタ連携エラー対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso010003j.util;

import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1ContractSpCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm1DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2ContractSpCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm2DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3BankAccountFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3ContractSpCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoBm3DestinationFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContainerCondSummaryVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCreateInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCreateInitVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractCustomerFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractManagementFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoInitBmInfoSummaryVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoInitBmInfoSummaryVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoLoginUserAuthorityVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoLoginUserSummaryVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoLoginUserSummaryVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoPageRenderVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoSalesCondSummaryVOImpl;
// 2015-02-02 [E_本稼動_12565] Add Start
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractOtherCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoSpDecisionHeadersSummuryVOImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoContractOtherCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso010003j.server.XxcsoSpDecisionHeadersSummuryVORowImpl;
import oracle.jbo.domain.Number;
// 2015-02-02 [E_本稼動_12565] Add End
import oracle.apps.fnd.framework.server.OADBTransaction;

/*******************************************************************************
 * 自販機設置契約情報登録初期ユーティリティクラス。
 * @author  SCS柳平直人
 * @version 1.1
 *******************************************************************************
 */
public class XxcsoContractRegistInitUtils 
{
  /*****************************************************************************
   * 新規作成時初期化処理
   * @param txn                OADBトランザクション
   * @param contractManagementId 自動販売機設置契約書ID
   * @param spDecisionHeaderId   SP専決ヘッダID
   * @param pageRdrVo            ページ属性設定ビューインスタンス
   * @param userAuthVo           ユーザー権限取得ビューインスタンス
   * @param userVo               ユーザー情報取得ビューインスタンス
   * @param createVo             初期表示情報取得ビューインスタンス
   * @param salesCondVo          売価別条件情報取得ビューインスタンス
   * @param contCondVo           一律条件・容器別条件情報取得ビューインスタンス
   * @param initBmVo             BM情報取得ビューインスタンス
   * @param mngVo                契約管理テーブル情報ビューインスタンス
   * @param cntrctVo             契約先テーブル情報ビューインスタンス
   * @param dest1Vo              BM1送付先テーブル情報ビューインスタンス
   * @param dest2Vo              BM2送付先テーブル情報ビューインスタンス
   * @param dest3Vo              BM3送付先テーブル情報ビューインスタンス
   * @param bank1Vo              BM1銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank1Vo              BM2銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank3Vo              BM3銀行口座アドオンテーブル情報ビューインスタンス
   * @param spCust1Vo            BM1SP専決顧客テーブル情報ビューインスタンス
   * @param spCust2Vo            BM2SP専決顧客テーブル情報ビューインスタンス
   * @param spCust3Vo            BM3SP専決顧客テーブル情報ビューインスタンス
   * @param contrOtherCustVo     契約先以外テーブル情報ビューインスタンス
   * @param spDecHedSumVo        SP専決ヘッダサマリ情報ビューインスタンス
   *****************************************************************************
   */
  public static void initCreate(
    OADBTransaction                      txn
   ,String                               spDecisionHeaderId
   ,XxcsoPageRenderVOImpl                pageRdrVo
   ,XxcsoLoginUserAuthorityVOImpl        userAuthVo
   ,XxcsoLoginUserSummaryVOImpl          userVo
   ,XxcsoContractCreateInitVOImpl        createVo
   ,XxcsoSalesCondSummaryVOImpl          salesCondVo
   ,XxcsoContainerCondSummaryVOImpl      contCondVo
   ,XxcsoInitBmInfoSummaryVOImpl         initBmVo
   ,XxcsoContractManagementFullVOImpl    mngVo
   ,XxcsoContractCustomerFullVOImpl      cntrctVo
   ,XxcsoBm1DestinationFullVOImpl        dest1Vo
   ,XxcsoBm2DestinationFullVOImpl        dest2Vo
   ,XxcsoBm3DestinationFullVOImpl        dest3Vo
   ,XxcsoBm1BankAccountFullVOImpl        bank1Vo
   ,XxcsoBm2BankAccountFullVOImpl        bank2Vo
   ,XxcsoBm3BankAccountFullVOImpl        bank3Vo
   ,XxcsoBm1ContractSpCustFullVOImpl     spCust1Vo
   ,XxcsoBm2ContractSpCustFullVOImpl     spCust2Vo
   ,XxcsoBm3ContractSpCustFullVOImpl     spCust3Vo
// 2015-02-02 [E_本稼動_12565] Add Start
   ,XxcsoContractOtherCustFullVOImpl     contrOtherCustVo
   ,XxcsoSpDecisionHeadersSummuryVOImpl  spDecHedSumVo
// 2015-02-02 [E_本稼動_12565] Add End
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    // page設定用VOの初期化
    pageRdrVo.executeQuery();
 
    // ログインユーザー権限情報取得用VOの初期化
    userAuthVo.initQuery(spDecisionHeaderId);

    // ログインユーザー情報取得用VOの初期化
    userVo.executeQuery();
    XxcsoLoginUserSummaryVORowImpl userRow
      = (XxcsoLoginUserSummaryVORowImpl)userVo.first();
    
    createVo.initQuery(spDecisionHeaderId);
    XxcsoContractCreateInitVORowImpl createRow
      = (XxcsoContractCreateInitVORowImpl)createVo.first();

    // 売価別条件情報取得VOの初期化
    salesCondVo.initQuery(spDecisionHeaderId);

    // 一律条件・容器別条件取得VOの初期化
    contCondVo.initQuery(spDecisionHeaderId);

    //////////////////////////////////////
    // 契約管理テーブルの初期化
    //////////////////////////////////////
    mngVo.initQuery((String)null);
    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl)mngVo.createRow();
    mngVo.insertRow(mngRow);
    mngRow.setSpDecisionHeaderId(    createRow.getSpDecisionHeaderId()        );
    mngRow.setSpDecisionNumber(      createRow.getSpDecisionNumber()          );
    mngRow.setContractCustomerId(    createRow.getCntrctCustomerId()          );
    mngRow.setContractFormat(        XxcsoContractRegistConstants.INIT_FORMAT );
    mngRow.setStatus(                XxcsoContractRegistConstants.INIT_STS    );
    mngRow.setEmployeeNumber(        userRow.getEmployeeNumber()              );
    mngRow.setFullName(              userRow.getFullName()                    );
    mngRow.setBaseCode(              userRow.getBaseCode()                    );
    mngRow.setBaseName(              userRow.getBaseName()                    );

    String lineCount = createRow.getLineCount();
    if ( ! "0".equals(lineCount) )
    {
      mngRow.setTransferMonthCode(
        XxcsoContractRegistConstants.INIT_TRANSFER_MONTH
      );
      mngRow.setTransferDayCode(
        XxcsoContractRegistConstants.INIT_TRANSFER_DAY
      );
      mngRow.setCloseDayCode(
        XxcsoContractRegistConstants.INIT_CLOSE_DAY
      );
    }

    mngRow.setCancellationOfferCode(
      XxcsoContractRegistConstants.INIT_CANCELLATION
    );
    mngRow.setInstallAccountId(       createRow.getInstallAccountId()         );
    mngRow.setInstallAccountNumber(   createRow.getInstallAccountNumber()     );
    mngRow.setInstallPartyName(       createRow.getInstallName()              );
    mngRow.setInstallPostalCode(      createRow.getInstallPostalCode()        );
    mngRow.setInstallState(           createRow.getInstallState()             );
    mngRow.setInstallCity(            createRow.getInstallCity()              );
    mngRow.setInstallAddress1(        createRow.getInstallAddress1()          );
    mngRow.setInstallAddress2(        createRow.getInstallAddress2()          );
    mngRow.setPublishDeptCode(        createRow.getSaleBaseCode()             );
    mngRow.setPublishDeptName(        createRow.getSaleBaseName()             );
    mngRow.setLocationAddress(        createRow.getLocationAddress()          );
    mngRow.setBaseLeaderName(         createRow.getBaseLeaderName()           );
    mngRow.setContractYearDate(       createRow.getContractYearDate()         );
    mngRow.setBaseLeaderPositionName( createRow.getBaseLeaderPositionName()   );
// 2015-02-02 [E_本稼動_12565] Del Start
//    mngRow.setOtherContent(           createRow.getOtherContent()             );
// 2015-02-02 [E_本稼動_12565] Del End
    
    //////////////////////////////////////
    // 契約先テーブルの初期化
    //////////////////////////////////////
    cntrctVo.initQuery(createRow.getCntrctCustomerId());

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM1)
    //////////////////////////////////////
    XxcsoInitBmInfoSummaryVORowImpl initBmRow = null;

    initBmVo.initQuery(createRow.getBm1SpCustId());
    initBmRow = (XxcsoInitBmInfoSummaryVORowImpl)initBmVo.first();

    if ( initBmRow != null )
    {
      spCust1Vo.initQuery(mngRow.getSpDecisionHeaderId());
      
      dest1Vo.first();
      XxcsoBm1DestinationFullVORowImpl dest1Row
        = (XxcsoBm1DestinationFullVORowImpl)dest1Vo.createRow();
      dest1Vo.insertRow(dest1Row);
      dest1Row.setVendorCode(           initBmRow.getVendorCode()             );
      dest1Row.setSupplierId(           initBmRow.getCustomerId()             );
      dest1Row.setDeliveryDiv(          XxcsoContractRegistConstants.DELIV_BM1);
      dest1Row.setPaymentName(          initBmRow.getVendorName()             );
      dest1Row.setPaymentNameAlt(       initBmRow.getVendorNameAlt()          );
      dest1Row.setBankTransferFeeChargeDiv(
        initBmRow.getTransferCommissionType()
      );
      dest1Row.setBellingDetailsDiv(    initBmRow.getBmPaymentType()          );
      dest1Row.setInqueryChargeHubCd(   initBmRow.getInquiryBaseCode()        );
      dest1Row.setInqueryChargeHubName( initBmRow.getInquiryBaseName()        );
      dest1Row.setPostCode(             initBmRow.getPostalCode()             );
      dest1Row.setPrefectures(          initBmRow.getState()                  );
      dest1Row.setCityWard(             initBmRow.getCity()                   );
      dest1Row.setAddress1(             initBmRow.getAddress1()               );
      dest1Row.setAddress2(             initBmRow.getAddress2()               );
      dest1Row.setAddressLinesPhonetic( initBmRow.getAddressLinesPhonetic()   );

      bank1Vo.first();
      XxcsoBm1BankAccountFullVORowImpl bank1Row
        = (XxcsoBm1BankAccountFullVORowImpl)bank1Vo.createRow();
      bank1Vo.insertRow(bank1Row);
      bank1Row.setBankNumber(           initBmRow.getBankNumber()             );
      bank1Row.setBankName(             initBmRow.getBankName()               );
      bank1Row.setBranchNumber(         initBmRow.getBankNum()                );
      bank1Row.setBranchName(           initBmRow.getBankBranchName()         );
      bank1Row.setBankAccountType(      initBmRow.getBankAccountType()        );
      bank1Row.setBankAccountNumber(    initBmRow.getBankAccountNum()         );
      bank1Row.setBankAccountNameKana(  initBmRow.getAccountHolderNameAlt()   );
      bank1Row.setBankAccountNameKanji( initBmRow.getAccountHolderName()      );
    }

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM2)
    //////////////////////////////////////
    initBmVo.initQuery(createRow.getBm2SpCustId());
    initBmRow = (XxcsoInitBmInfoSummaryVORowImpl)initBmVo.first();

    if ( initBmRow != null )
    {
      spCust2Vo.initQuery(mngRow.getSpDecisionHeaderId());
      
      dest2Vo.first();
      XxcsoBm2DestinationFullVORowImpl dest2Row
        = (XxcsoBm2DestinationFullVORowImpl)dest2Vo.createRow();
      dest2Vo.insertRow(dest2Row);
      dest2Row.setVendorCode(           initBmRow.getVendorCode()             );
      dest2Row.setSupplierId(           initBmRow.getCustomerId()             );
      dest2Row.setDeliveryDiv(          XxcsoContractRegistConstants.DELIV_BM2);
      dest2Row.setPaymentName(          initBmRow.getVendorName()             );
      dest2Row.setPaymentNameAlt(       initBmRow.getVendorNameAlt()          );
      dest2Row.setBankTransferFeeChargeDiv(
        initBmRow.getTransferCommissionType()
      );
      dest2Row.setBellingDetailsDiv(    initBmRow.getBmPaymentType()          );
      dest2Row.setInqueryChargeHubCd(   initBmRow.getInquiryBaseCode()        );
      dest2Row.setInqueryChargeHubName( initBmRow.getInquiryBaseName()        );
      dest2Row.setPostCode(             initBmRow.getPostalCode()             );
      dest2Row.setPrefectures(          initBmRow.getState()                  );
      dest2Row.setCityWard(             initBmRow.getCity()                   );
      dest2Row.setAddress1(             initBmRow.getAddress1()               );
      dest2Row.setAddress2(             initBmRow.getAddress2()               );
      dest2Row.setAddressLinesPhonetic( initBmRow.getAddressLinesPhonetic()   );

      bank2Vo.first();
      XxcsoBm2BankAccountFullVORowImpl bank2Row
        = (XxcsoBm2BankAccountFullVORowImpl)bank2Vo.createRow();
      bank2Vo.insertRow(bank2Row);
      bank2Row.setBankNumber(           initBmRow.getBankNumber()             );
      bank2Row.setBankName(             initBmRow.getBankName()               );
      bank2Row.setBranchNumber(         initBmRow.getBankNum()                );
      bank2Row.setBranchName(           initBmRow.getBankBranchName()         );
      bank2Row.setBankAccountType(      initBmRow.getBankAccountType()        );
      bank2Row.setBankAccountNumber(    initBmRow.getBankAccountNum()         );
      bank2Row.setBankAccountNameKana(  initBmRow.getAccountHolderNameAlt()   );
      bank2Row.setBankAccountNameKanji( initBmRow.getAccountHolderName()      );
    }

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM3)
    //////////////////////////////////////
    initBmVo.initQuery(createRow.getBm3SpCustId());
    initBmRow = (XxcsoInitBmInfoSummaryVORowImpl)initBmVo.first();

    if ( initBmRow != null )
    {
      spCust3Vo.initQuery(mngRow.getSpDecisionHeaderId());
      
      dest3Vo.first();
      XxcsoBm3DestinationFullVORowImpl dest3Row
        = (XxcsoBm3DestinationFullVORowImpl)dest3Vo.createRow();
      dest3Vo.insertRow(dest3Row);
      dest3Row.setVendorCode(           initBmRow.getVendorCode()             );
      dest3Row.setSupplierId(           initBmRow.getCustomerId()             );
      dest3Row.setDeliveryDiv(          XxcsoContractRegistConstants.DELIV_BM3);
      dest3Row.setPaymentName(          initBmRow.getVendorName());
      dest3Row.setPaymentNameAlt(       initBmRow.getVendorNameAlt());
      dest3Row.setBankTransferFeeChargeDiv(
        initBmRow.getTransferCommissionType()
      );
      dest3Row.setBellingDetailsDiv(    initBmRow.getBmPaymentType()          );
      dest3Row.setInqueryChargeHubCd(   initBmRow.getInquiryBaseCode()        );
      dest3Row.setInqueryChargeHubName( initBmRow.getInquiryBaseName()        );
      dest3Row.setPostCode(             initBmRow.getPostalCode()             );
      dest3Row.setPrefectures(          initBmRow.getState()                  );
      dest3Row.setCityWard(             initBmRow.getCity()                   );
      dest3Row.setAddress1(             initBmRow.getAddress1()               );
      dest3Row.setAddress2(             initBmRow.getAddress2()               );
      dest3Row.setAddressLinesPhonetic( initBmRow.getAddressLinesPhonetic()   );

      bank3Vo.first();
      XxcsoBm3BankAccountFullVORowImpl bank3Row
        = (XxcsoBm3BankAccountFullVORowImpl)bank3Vo.createRow();
      bank3Vo.insertRow(bank3Row);
      bank3Row.setBankNumber(           initBmRow.getBankNumber()             );
      bank3Row.setBankName(             initBmRow.getBankName()               );
      bank3Row.setBranchNumber(         initBmRow.getBankNum()                );
      bank3Row.setBranchName(           initBmRow.getBankBranchName()         );
      bank3Row.setBankAccountType(      initBmRow.getBankAccountType()        );
      bank3Row.setBankAccountNumber(    initBmRow.getBankAccountNum()         );
      bank3Row.setBankAccountNameKana(  initBmRow.getAccountHolderNameAlt()   );
      bank3Row.setBankAccountNameKanji( initBmRow.getAccountHolderName()      );
    }
// 2015-02-02 [E_本稼動_12565] Add Start
    //////////////////////////////////////
    // 契約先以外テーブルの初期化
    //////////////////////////////////////
    if ( (createRow.getInstSuppType() != null
           && createRow.getInstSuppType().equals(XxcsoContractRegistConstants.INST_SUPP_TYPE1))
      || (createRow.getIntroChgType() != null
           && createRow.getIntroChgType().equals(XxcsoContractRegistConstants.INTRO_CHG_TYPE1))
      || (createRow.getElectricPaymentType() != null
           &&createRow.getElectricPaymentType().equals(XxcsoContractRegistConstants.ELECTRIC_PAYMENT_TYPE2))
    )
    {
      contrOtherCustVo.initQuery((oracle.jbo.domain.Number)null);
      XxcsoContractOtherCustFullVORowImpl contrOtherCustRow
        = (XxcsoContractOtherCustFullVORowImpl)contrOtherCustVo.createRow();
      contrOtherCustVo.insertRow(contrOtherCustRow);

      // SP専決ヘッダサマリVOの初期化
      spDecHedSumVo.first();
      XxcsoSpDecisionHeadersSummuryVORowImpl spDecHedSumRow
        = (XxcsoSpDecisionHeadersSummuryVORowImpl) spDecHedSumVo.first();

      // チェックボックスがチェックの場合は初期値を設定
      // 設置協賛金リージョン
      if(createRow.getInstSuppType() != null
            && createRow.getInstSuppType().equals(XxcsoContractRegistConstants.INST_SUPP_TYPE1))
      {
        // 振込手数料負担
        if(contrOtherCustRow.getInstallSuppBkChgBearer() == null)
        {
          contrOtherCustRow.setInstallSuppBkChgBearer("I");
        }
        // 口座種別
        if(contrOtherCustRow.getInstallSuppBkAcctType() == null)
        {
          contrOtherCustRow.setInstallSuppBkAcctType("1");
        }
      }
      // 紹介手数料リージョン
      if(createRow.getIntroChgType() != null
           && createRow.getIntroChgType().equals(XxcsoContractRegistConstants.INTRO_CHG_TYPE1))
      {
        // 振込手数料負担
        if(contrOtherCustRow.getIntroChgBkChgBearer() == null){
          contrOtherCustRow.setIntroChgBkChgBearer("I");
        }
        // 口座種別
        if(contrOtherCustRow.getIntroChgBkAcctType() == null)
        {
          contrOtherCustRow.setIntroChgBkAcctType("1");
        }
      }
      // 電気代リージョン
      if( createRow.getElectricPaymentType() != null
           && createRow.getElectricPaymentType().equals(XxcsoContractRegistConstants.ELECTRIC_PAYMENT_TYPE2))
      {
        // 振込手数料負担
        if(contrOtherCustRow.getElectricBkChgBearer() == null)
        {
          contrOtherCustRow.setElectricBkChgBearer("I");
        }
        // 口座種別
        if(contrOtherCustRow.getElectricBkAcctType() == null)
        {
          contrOtherCustRow.setElectricBkAcctType("1");
        }
      }
    }
// 2015-02-02 [E_本稼動_12565] Add End
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * 更新時初期化処理
   * @param txn                  OADBトランザクション
   * @param contractManagementId 自動販売機設置契約書ID
   * @param spDecisionHeaderId   SP専決ヘッダID
   * @param pageRdrVo            ページ属性設定ビューインスタンス
   * @param userVo               ユーザー情報取得ビューインスタンス
   * @param salesCondVo          売価別条件情報取得ビューインスタンス
   * @param contCondVo           一律条件・容器別条件情報取得ビューインスタンス
   * @param initBmVo             BM情報取得ビューインスタンス
   * @param mngVo                契約管理テーブル情報ビューインスタンス
   * @param cntrctVo             契約先テーブル情報ビューインスタンス
   * @param dest1Vo              BM1送付先テーブル情報ビューインスタンス
   * @param dest2Vo              BM2送付先テーブル情報ビューインスタンス
   * @param dest3Vo              BM3送付先テーブル情報ビューインスタンス
   * @param bank1Vo              BM1銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank1Vo              BM2銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank3Vo              BM3銀行口座アドオンテーブル情報ビューインスタンス
   * @param spCust1Vo            BM1SP専決顧客テーブル情報ビューインスタンス
   * @param spCust2Vo            BM2SP専決顧客テーブル情報ビューインスタンス
   * @param spCust3Vo            BM3SP専決顧客テーブル情報ビューインスタンス
   * @param contrOtherCustVo     契約先以外テーブル情報ビューインスタンス
   * @param spDecHedSumVo        SP専決ヘッダサマリ情報ビューインスタンス
   *****************************************************************************
   */
  public static void initUpdate(
    OADBTransaction                      txn
   ,String                               contractManagementId
   ,String                               spDecisionHeaderId
   ,XxcsoPageRenderVOImpl                pageRdrVo
   ,XxcsoLoginUserAuthorityVOImpl        userAuthVo
   ,XxcsoLoginUserSummaryVOImpl          userVo
   ,XxcsoContractCreateInitVOImpl        createVo
   ,XxcsoSalesCondSummaryVOImpl          salesCondVo
   ,XxcsoContainerCondSummaryVOImpl      contCondVo
   ,XxcsoInitBmInfoSummaryVOImpl         initBmVo
   ,XxcsoContractManagementFullVOImpl    mngVo
   ,XxcsoContractCustomerFullVOImpl      cntrctVo
   ,XxcsoBm1DestinationFullVOImpl        dest1Vo
   ,XxcsoBm2DestinationFullVOImpl        dest2Vo
   ,XxcsoBm3DestinationFullVOImpl        dest3Vo
   ,XxcsoBm1BankAccountFullVOImpl        bank1Vo
   ,XxcsoBm2BankAccountFullVOImpl        bank2Vo
   ,XxcsoBm3BankAccountFullVOImpl        bank3Vo
   ,XxcsoBm1ContractSpCustFullVOImpl     spCust1Vo
   ,XxcsoBm2ContractSpCustFullVOImpl     spCust2Vo
   ,XxcsoBm3ContractSpCustFullVOImpl     spCust3Vo
// 2015-02-02 [E_本稼動_12565] Add Start
   ,XxcsoContractOtherCustFullVOImpl     contrOtherCustVo
   ,XxcsoSpDecisionHeadersSummuryVOImpl  spDecHedSumVo
// 2015-02-02 [E_本稼動_12565] Add End
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    // page設定用VOの初期化
    pageRdrVo.executeQuery();
 
    // ログインユーザー情報取得用VOの初期化
    userAuthVo.initQuery(spDecisionHeaderId);

    userVo.executeQuery();
    XxcsoLoginUserSummaryVORowImpl userRow
      = (XxcsoLoginUserSummaryVORowImpl) userVo.first();
    
    createVo.initQuery(spDecisionHeaderId);
    XxcsoContractCreateInitVORowImpl createRow
      = (XxcsoContractCreateInitVORowImpl) createVo.first();

    // 売価別条件情報取得VOの初期化
    salesCondVo.initQuery(spDecisionHeaderId);

    // 一律条件・容器別条件取得VOの初期化
    contCondVo.initQuery(spDecisionHeaderId);

    //////////////////////////////////////
    // 契約管理テーブルの初期化
    //////////////////////////////////////
    mngVo.initQuery(contractManagementId);
    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl) mngVo.first();

    //////////////////////////////////////
    // 契約先テーブルの初期化
    //////////////////////////////////////
    cntrctVo.initQuery(createRow.getCntrctCustomerId());

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM1)
    //////////////////////////////////////
    spCust1Vo.initQuery(mngRow.getSpDecisionHeaderId());
    dest1Vo.first();
    bank1Vo.first();

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM2)
    //////////////////////////////////////
    spCust2Vo.initQuery(mngRow.getSpDecisionHeaderId());
    dest2Vo.first();
    bank2Vo.first();

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM3)
    //////////////////////////////////////
    spCust3Vo.initQuery(mngRow.getSpDecisionHeaderId());
    dest3Vo.first();
    bank3Vo.first();

    XxcsoUtils.debug(txn, "[END]");
// 2015-02-02 [E_本稼動_12565] Add Start
    //////////////////////////////////////
    // 契約先以外テーブルの初期化
    //////////////////////////////////////
    contrOtherCustVo.initQuery(mngRow.getContractOtherCustsId());
    XxcsoContractOtherCustFullVORowImpl contrOtherCustRow
      = (XxcsoContractOtherCustFullVORowImpl) contrOtherCustVo.first();

    // SP専決ヘッダサマリVOの初期化
    spDecHedSumVo.first();
    XxcsoSpDecisionHeadersSummuryVORowImpl spDecHedSumRow
      = (XxcsoSpDecisionHeadersSummuryVORowImpl) spDecHedSumVo.first();
    
    // 契約先以外テーブルのデータが存在する場合
    if ( contrOtherCustRow != null )
    {
      // // チェックボックスがチェックかつ、該当項目がNULLの場合は初期値を設定
      // 設置協賛金リージョン
      if( createRow.getInstSuppType() != null
           && createRow.getInstSuppType().equals(XxcsoContractRegistConstants.INST_SUPP_TYPE1))
      {
        // 振込手数料負担
        if(contrOtherCustRow.getInstallSuppBkChgBearer() == null)
        {
          contrOtherCustRow.setInstallSuppBkChgBearer("I");
        }
        // 口座種別
        if(contrOtherCustRow.getInstallSuppBkAcctType() == null)
        {
          contrOtherCustRow.setInstallSuppBkAcctType("1");
        }
      }
      // 紹介手数料リージョン
      if( createRow.getIntroChgType() != null
           && createRow.getIntroChgType().equals(XxcsoContractRegistConstants.INTRO_CHG_TYPE1))
      {
        // 振込手数料負担
        if(contrOtherCustRow.getIntroChgBkChgBearer() == null){
          contrOtherCustRow.setIntroChgBkChgBearer("I");
        }
        // 口座種別
        if(contrOtherCustRow.getIntroChgBkAcctType() == null)
        {
          contrOtherCustRow.setIntroChgBkAcctType("1");
        }
      }
      // 電気代リージョン
      if( createRow.getElectricPaymentType() != null
           && createRow.getElectricPaymentType().equals(XxcsoContractRegistConstants.ELECTRIC_PAYMENT_TYPE2))
      {
        // 振込手数料負担
        if(contrOtherCustRow.getElectricBkChgBearer() == null)
        {
          contrOtherCustRow.setElectricBkChgBearer("I");
        }
        // 口座種別
        if(contrOtherCustRow.getElectricBkAcctType() == null)
        {
          contrOtherCustRow.setElectricBkAcctType("1");
        }
      }
    }
// 2015-02-02 [E_本稼動_12565] Add End
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * コピー時初期化処理
   * @param txn                OADBトランザクション
   * @param contractManagementId 自動販売機設置契約書ID
   * @param spDecisionHeaderId   SP専決ヘッダID
   * @param pageRdrVo            ページ属性設定ビューインスタンス
   * @param userVo               ユーザー情報取得ビューインスタンス
   * @param createVo             初期表示情報取得ビューインスタンス
   * @param salesCondVo          売価別条件情報取得ビューインスタンス
   * @param contCondVo           一律条件・容器別条件情報取得ビューインスタンス
   * @param initBmVo             BM情報取得ビューインスタンス
   * @param mngVo                契約管理テーブル情報ビューインスタンス
   * @param cntrctVo             契約先テーブル情報ビューインスタンス
   * @param dest1Vo              BM1送付先テーブル情報ビューインスタンス
   * @param dest2Vo              BM2送付先テーブル情報ビューインスタンス
   * @param dest3Vo              BM3送付先テーブル情報ビューインスタンス
   * @param bank1Vo              BM1銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank1Vo              BM2銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank3Vo              BM3銀行口座アドオンテーブル情報ビューインスタンス
   * @param spCust1Vo            BM1SP専決顧客テーブル情報ビューインスタンス
   * @param spCust2Vo            BM2SP専決顧客テーブル情報ビューインスタンス
   * @param spCust3Vo            BM3SP専決顧客テーブル情報ビューインスタンス
   * @param mngVo2               コピー用契約管理テーブル情報ビューインスタンス
   * @param dest1Vo2             コピー用BM1送付先テーブル情報ビューインスタンス
   * @param dest2Vo2             コピー用BM2送付先テーブル情報ビューインスタンス
   * @param dest3Vo2             コピー用BM3送付先テーブル情報ビューインスタンス
   * @param bank1Vo2             コピー用BM1銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank1Vo2             コピー用BM2銀行口座アドオンテーブル情報ビューインスタンス
   * @param bank3Vo2             コピー用BM3銀行口座アドオンテーブル情報ビューインスタンス
   * @param contrOtherCustVo      契約先以外テーブル情報ビューインスタンス
   * @param spDecHedSumVo         SP専決ヘッダサマリ情報ビューインスタンス
   * @param contrOtherCustVo2     コピー用契約先以外テーブル情報ビューインスタンス
   *****************************************************************************
   */
  public static void initCopy(
    OADBTransaction                      txn
   ,String                               contractManagementId
   ,String                               spDecisionHeaderId
   ,XxcsoPageRenderVOImpl                pageRdrVo
   ,XxcsoLoginUserAuthorityVOImpl        userAuthVo
   ,XxcsoLoginUserSummaryVOImpl          userVo
   ,XxcsoContractCreateInitVOImpl        createVo
   ,XxcsoSalesCondSummaryVOImpl          salesCondVo
   ,XxcsoContainerCondSummaryVOImpl      contCondVo
   ,XxcsoInitBmInfoSummaryVOImpl         initBmVo
   ,XxcsoContractManagementFullVOImpl    mngVo
   ,XxcsoContractCustomerFullVOImpl      cntrctVo
   ,XxcsoBm1DestinationFullVOImpl        dest1Vo
   ,XxcsoBm2DestinationFullVOImpl        dest2Vo
   ,XxcsoBm3DestinationFullVOImpl        dest3Vo
   ,XxcsoBm1BankAccountFullVOImpl        bank1Vo
   ,XxcsoBm2BankAccountFullVOImpl        bank2Vo
   ,XxcsoBm3BankAccountFullVOImpl        bank3Vo
   ,XxcsoBm1ContractSpCustFullVOImpl     spCust1Vo
   ,XxcsoBm2ContractSpCustFullVOImpl     spCust2Vo
   ,XxcsoBm3ContractSpCustFullVOImpl     spCust3Vo
   ,XxcsoContractManagementFullVOImpl    mngVo2
   ,XxcsoBm1DestinationFullVOImpl        dest1Vo2
   ,XxcsoBm2DestinationFullVOImpl        dest2Vo2
   ,XxcsoBm3DestinationFullVOImpl        dest3Vo2
   ,XxcsoBm1BankAccountFullVOImpl        bank1Vo2
   ,XxcsoBm2BankAccountFullVOImpl        bank2Vo2
   ,XxcsoBm3BankAccountFullVOImpl        bank3Vo2
// 2015-02-02 [E_本稼動_12565] Add Start
   ,XxcsoContractOtherCustFullVOImpl     contrOtherCustVo
   ,XxcsoSpDecisionHeadersSummuryVOImpl  spDecHedSumVo
   ,XxcsoContractOtherCustFullVOImpl     contrOtherCustVo2
// 2015-02-02 [E_本稼動_12565] Add End
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    // page設定用VOの初期化
    pageRdrVo.executeQuery();
 
    // ログインユーザー情報取得用VOの初期化
    userAuthVo.initQuery(spDecisionHeaderId);

    userVo.executeQuery();
    XxcsoLoginUserSummaryVORowImpl userRow
      = (XxcsoLoginUserSummaryVORowImpl) userVo.first();
    
    createVo.initQuery(spDecisionHeaderId);
    XxcsoContractCreateInitVORowImpl createRow
      = (XxcsoContractCreateInitVORowImpl) createVo.first();

    // 売価別条件情報取得VOの初期化
    salesCondVo.initQuery(spDecisionHeaderId);

    // 一律条件・容器別条件取得VOの初期化
    contCondVo.initQuery(spDecisionHeaderId);

    //////////////////////////////////////
    // コピー用契約管理テーブルの初期化
    //////////////////////////////////////
    mngVo2.initQuery(contractManagementId);
    XxcsoContractManagementFullVORowImpl mngRow2
      = (XxcsoContractManagementFullVORowImpl) mngVo2.first();

    //////////////////////////////////////
    // 契約管理テーブルの初期化
    //////////////////////////////////////
    mngVo.initQuery((String)null);
    XxcsoContractManagementFullVORowImpl mngRow
      = (XxcsoContractManagementFullVORowImpl)mngVo.createRow();
    mngVo.insertRow(mngRow);
    mngRow.setSpDecisionHeaderId(     mngRow2.getSpDecisionHeaderId()         );
    mngRow.setSpDecisionNumber(       mngRow2.getSpDecisionNumber()           );
    mngRow.setContractCustomerId(     mngRow2.getContractCustomerId()         );
    mngRow.setContractFormat(         mngRow2.getContractFormat()             );
    mngRow.setStatus(                 XxcsoContractRegistConstants.INIT_STS   );
    mngRow.setEmployeeNumber(         userRow.getEmployeeNumber()             );
    mngRow.setFullName(               userRow.getFullName()                   );
    mngRow.setBaseCode(               userRow.getBaseCode()                   );
    mngRow.setBaseName(               userRow.getBaseName()                   );

    String lineCount = createRow.getLineCount();
    if ( ! "0".equals(lineCount) )
    {
      mngRow.setTransferMonthCode(    mngRow2.getTransferMonthCode()          );
      mngRow.setTransferDayCode(      mngRow2.getTransferDayCode()            );
      mngRow.setCloseDayCode(         mngRow2.getCloseDayCode()               );
    }

    mngRow.setCancellationOfferCode(  mngRow2.getCancellationOfferCode()      );
    mngRow.setInstallAccountId(       mngRow2.getInstallAccountId()           );
    mngRow.setInstallAccountNumber(   mngRow2.getInstallAccountNumber()       );
    mngRow.setInstallPartyName(       mngRow2.getInstallPartyName()           );
    mngRow.setInstallPostalCode(      mngRow2.getInstallPostalCode()          );
    mngRow.setInstallState(           mngRow2.getInstallState()               );
    mngRow.setInstallCity(            mngRow2.getInstallCity()                );
    mngRow.setInstallAddress1(        mngRow2.getInstallAddress1()            );
    mngRow.setInstallAddress2(        mngRow2.getInstallAddress2()            );
    mngRow.setContractEffectDate(     mngRow2.getContractEffectDate()         );
    mngRow.setInstallDate(            mngRow2.getInstallDate()                );
// 2015-11-26 [E_本稼動_13345] Del Start
//    mngRow.setInstallCode(            mngRow2.getInstallCode()                );
// 2015-11-26 [E_本稼動_13345] Del End
// 2009-05-25 [ST障害T1_1136] Add Start
    mngRow.setInstanceId(             mngRow2.getInstanceId()                 );
// 2009-05-25 [ST障害T1_1136] Add End
    mngRow.setPublishDeptCode(        mngRow2.getPublishDeptCode()            );
    mngRow.setPublishDeptName(        mngRow2.getPublishDeptName()            );
    mngRow.setLocationAddress(        mngRow2.getLocationAddress()            );
    mngRow.setBaseLeaderName(         mngRow2.getBaseLeaderName()             );
    mngRow.setContractYearDate(       mngRow2.getContractYearDate()           );
    mngRow.setBaseLeaderPositionName( mngRow2.getBaseLeaderPositionName()     );
// 2015-02-02 [E_本稼動_12565] Del Start
//    mngRow.setOtherContent(           mngRow2.getOtherContent()               );
// 2015-02-02 [E_本稼動_12565] Del End

    //////////////////////////////////////
    // 契約先テーブルの初期化
    //////////////////////////////////////
    cntrctVo.initQuery(createRow.getCntrctCustomerId());

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM1)
    //////////////////////////////////////
    XxcsoBm1DestinationFullVORowImpl dest1Row2 =
      (XxcsoBm1DestinationFullVORowImpl) dest1Vo2.first();
    XxcsoBm1BankAccountFullVORowImpl bank1Row2 =
      (XxcsoBm1BankAccountFullVORowImpl) bank1Vo2.first();

      
    if ( dest1Row2 != null )
    {
      spCust1Vo.initQuery(mngRow.getSpDecisionHeaderId());

      dest1Vo.first();
      XxcsoBm1DestinationFullVORowImpl dest1Row
        = (XxcsoBm1DestinationFullVORowImpl)dest1Vo.createRow();
      dest1Vo.insertRow(dest1Row);

      dest1Row.setVendorCode(           dest1Row2.getVendorCode()             );
      dest1Row.setSupplierId(           dest1Row2.getSupplierId()             );
      dest1Row.setDeliveryDiv(          dest1Row2.getDeliveryDiv()            );
      dest1Row.setPaymentName(          dest1Row2.getPaymentName()            );
      dest1Row.setPaymentNameAlt(       dest1Row2.getPaymentNameAlt()         );
      dest1Row.setBankTransferFeeChargeDiv(
        dest1Row2.getBankTransferFeeChargeDiv()
      );
      dest1Row.setBellingDetailsDiv(    dest1Row2.getBellingDetailsDiv()      );
      dest1Row.setInqueryChargeHubCd(   dest1Row2.getInqueryChargeHubCd()     );
      dest1Row.setInqueryChargeHubName( dest1Row2.getInqueryChargeHubName()   );
      dest1Row.setPostCode(             dest1Row2.getPostCode()               );
      dest1Row.setPrefectures(          dest1Row2.getPrefectures()            );
      dest1Row.setCityWard(             dest1Row2.getCityWard()               );
      dest1Row.setAddress1(             dest1Row2.getAddress1()               );
      dest1Row.setAddress2(             dest1Row2.getAddress2()               );
      dest1Row.setAddressLinesPhonetic( dest1Row2.getAddressLinesPhonetic()   );
    }

    if ( bank1Row2 != null )
    {
      bank1Vo.first();
      XxcsoBm1BankAccountFullVORowImpl bank1Row
        = (XxcsoBm1BankAccountFullVORowImpl)bank1Vo.createRow();
      bank1Vo.insertRow(bank1Row);

      bank1Row.setBankNumber(           bank1Row2.getBankNumber()             );
      bank1Row.setBankName(             bank1Row2.getBankName()               );
      bank1Row.setBranchNumber(         bank1Row2.getBranchNumber()           );
      bank1Row.setBranchName(           bank1Row2.getBranchName()             );
      bank1Row.setBankAccountType(      bank1Row2.getBankAccountType()        );
      bank1Row.setBankAccountNumber(    bank1Row2.getBankAccountNumber()      );
      bank1Row.setBankAccountNameKana(  bank1Row2.getBankAccountNameKana()    );
      bank1Row.setBankAccountNameKanji( bank1Row2.getBankAccountNameKanji()   );
    }

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM2)
    //////////////////////////////////////
    XxcsoBm2DestinationFullVORowImpl dest2Row2 =
      (XxcsoBm2DestinationFullVORowImpl) dest2Vo2.first();
    XxcsoBm2BankAccountFullVORowImpl bank2Row2 =
      (XxcsoBm2BankAccountFullVORowImpl) bank2Vo2.first();

    if ( dest2Row2 != null )
    {
      spCust2Vo.initQuery(mngRow.getSpDecisionHeaderId());
      
      dest2Vo.first();
      XxcsoBm2DestinationFullVORowImpl dest2Row
        = (XxcsoBm2DestinationFullVORowImpl)dest2Vo.createRow();
      dest2Vo.insertRow(dest2Row);

      dest2Row.setVendorCode(           dest2Row2.getVendorCode()             );
      dest2Row.setSupplierId(           dest2Row2.getSupplierId()             );
      dest2Row.setDeliveryDiv(          dest2Row2.getDeliveryDiv()            );
      dest2Row.setPaymentName(          dest2Row2.getPaymentName()            );
      dest2Row.setPaymentNameAlt(       dest2Row2.getPaymentNameAlt()         );
      dest2Row.setBankTransferFeeChargeDiv(
        dest2Row2.getBankTransferFeeChargeDiv()
      );
      dest2Row.setBellingDetailsDiv(    dest2Row2.getBellingDetailsDiv()      );
      dest2Row.setInqueryChargeHubCd(   dest2Row2.getInqueryChargeHubCd()     );
      dest2Row.setInqueryChargeHubName( dest2Row2.getInqueryChargeHubName()   );
      dest2Row.setPostCode(             dest2Row2.getPostCode()               );
      dest2Row.setPrefectures(          dest2Row2.getPrefectures()            );
      dest2Row.setCityWard(             dest2Row2.getCityWard()               );
      dest2Row.setAddress1(             dest2Row2.getAddress1()               );
      dest2Row.setAddress2(             dest2Row2.getAddress2()               );
      dest2Row.setAddressLinesPhonetic( dest2Row2.getAddressLinesPhonetic()   );
    }

    if ( bank2Row2 != null )
    {
      bank2Vo.first();
      XxcsoBm2BankAccountFullVORowImpl bank2Row
        = (XxcsoBm2BankAccountFullVORowImpl)bank2Vo.createRow();
      bank2Vo.insertRow(bank2Row);

      bank2Row.setBankNumber(           bank2Row2.getBankNumber()             );
      bank2Row.setBankName(             bank2Row2.getBankName()               );
      bank2Row.setBranchNumber(         bank2Row2.getBranchNumber()           );
      bank2Row.setBranchName(           bank2Row2.getBranchName()             );
      bank2Row.setBankAccountType(      bank2Row2.getBankAccountType()        );
      bank2Row.setBankAccountNumber(    bank2Row2.getBankAccountNumber()      );
      bank2Row.setBankAccountNameKana(  bank2Row2.getBankAccountNameKana()    );
      bank2Row.setBankAccountNameKanji( bank2Row2.getBankAccountNameKanji()   );
    }

    //////////////////////////////////////
    // 送付先テーブルの初期化(BM3)
    //////////////////////////////////////
    XxcsoBm3DestinationFullVORowImpl dest3Row2 =
      (XxcsoBm3DestinationFullVORowImpl) dest3Vo2.first();
    XxcsoBm3BankAccountFullVORowImpl bank3Row2 =
      (XxcsoBm3BankAccountFullVORowImpl) bank3Vo2.first();

    spCust3Vo.initQuery(mngRow.getSpDecisionHeaderId());
      
    if ( dest3Row2 != null )
    {
      dest3Vo.first();
      XxcsoBm3DestinationFullVORowImpl dest3Row
        = (XxcsoBm3DestinationFullVORowImpl) dest3Vo.createRow();
      dest3Vo.insertRow(dest3Row);

      dest3Row.setVendorCode(           dest3Row2.getVendorCode()             );
      dest3Row.setSupplierId(           dest3Row2.getSupplierId()             );
      dest3Row.setDeliveryDiv(          dest3Row2.getDeliveryDiv()            );
      dest3Row.setPaymentName(          dest3Row2.getPaymentName()            );
      dest3Row.setPaymentNameAlt(       dest3Row2.getPaymentNameAlt()         );
      dest3Row.setBankTransferFeeChargeDiv(
        dest3Row2.getBankTransferFeeChargeDiv()
      );
      dest3Row.setBellingDetailsDiv(    dest3Row2.getBellingDetailsDiv()      );
      dest3Row.setInqueryChargeHubCd(   dest3Row2.getInqueryChargeHubCd()     );
      dest3Row.setInqueryChargeHubName( dest3Row2.getInqueryChargeHubName()   );
      dest3Row.setPostCode(             dest3Row2.getPostCode()               );
      dest3Row.setPrefectures(          dest3Row2.getPrefectures()            );
      dest3Row.setCityWard(             dest3Row2.getCityWard()               );
      dest3Row.setAddress1(             dest3Row2.getAddress1()               );
      dest3Row.setAddress2(             dest3Row2.getAddress2()               );
      dest3Row.setAddressLinesPhonetic( dest3Row2.getAddressLinesPhonetic()   );
    }

    if ( bank3Row2 != null )
    {
      bank3Vo.first();
      XxcsoBm3BankAccountFullVORowImpl bank3Row
        = (XxcsoBm3BankAccountFullVORowImpl)bank3Vo.createRow();
      bank3Vo.insertRow(bank3Row);

      bank3Row.setBankNumber(           bank3Row2.getBankNumber()             );
      bank3Row.setBankName(             bank3Row2.getBankName()               );
      bank3Row.setBranchNumber(         bank3Row2.getBranchNumber()           );
      bank3Row.setBranchName(           bank3Row2.getBranchName()             );
      bank3Row.setBankAccountType(      bank3Row2.getBankAccountType()        );
      bank3Row.setBankAccountNumber(    bank3Row2.getBankAccountNumber()      );
      bank3Row.setBankAccountNameKana(  bank3Row2.getBankAccountNameKana()    );
      bank3Row.setBankAccountNameKanji( bank3Row2.getBankAccountNameKanji()   );
    }
    
// 2015-02-02 [E_本稼動_12565] Add Start
    //////////////////////////////////////
    // コピー用契約先以外テーブルの初期化
    //////////////////////////////////////
    contrOtherCustVo2.initQuery(mngRow2.getContractOtherCustsId());
    XxcsoContractOtherCustFullVORowImpl contrOtherCustRow2 =
      (XxcsoContractOtherCustFullVORowImpl) contrOtherCustVo2.first();

    //////////////////////////////////////
    // 契約先以外テーブルの初期化
    //////////////////////////////////////
    if ( contrOtherCustRow2 != null)
    {
      contrOtherCustVo.initQuery((oracle.jbo.domain.Number)null);
      XxcsoContractOtherCustFullVORowImpl contrOtherCustRow
        = (XxcsoContractOtherCustFullVORowImpl)contrOtherCustVo.createRow();
      contrOtherCustVo.insertRow(contrOtherCustRow);
      contrOtherCustRow.setInstallSuppBkChgBearer(   contrOtherCustRow2.getInstallSuppBkChgBearer()   );
      contrOtherCustRow.setInstallSuppBkNumber(      contrOtherCustRow2.getInstallSuppBkNumber()      );
      contrOtherCustRow.setInstallSuppBranchNumber(  contrOtherCustRow2.getInstallSuppBranchNumber()  );
      contrOtherCustRow.setInstSuppBankName(         contrOtherCustRow2.getInstSuppBankName()         );
      contrOtherCustRow.setInstSuppBankBranchName(   contrOtherCustRow2.getInstSuppBankBranchName()   );
      contrOtherCustRow.setInstallSuppBkAcctType(    contrOtherCustRow2.getInstallSuppBkAcctType()    );
      contrOtherCustRow.setInstallSuppBkAcctNumber(  contrOtherCustRow2.getInstallSuppBkAcctNumber()  );
      contrOtherCustRow.setInstallSuppBkAcctNameAlt( contrOtherCustRow2.getInstallSuppBkAcctNameAlt() );
      contrOtherCustRow.setInstallSuppBkAcctName(    contrOtherCustRow2.getInstallSuppBkAcctName()    );
      contrOtherCustRow.setIntroChgBkChgBearer(      contrOtherCustRow2.getIntroChgBkChgBearer()      );
      contrOtherCustRow.setIntroChgBkNumber(         contrOtherCustRow2.getIntroChgBkNumber()         );
      contrOtherCustRow.setIntroChgBranchNumber(     contrOtherCustRow2.getIntroChgBranchNumber()     );
      contrOtherCustRow.setIntroChgBankName(         contrOtherCustRow2.getIntroChgBankName()         );
      contrOtherCustRow.setIntroChgBankBranchName(   contrOtherCustRow2.getIntroChgBankBranchName()   );
      contrOtherCustRow.setIntroChgBkAcctType(       contrOtherCustRow2.getIntroChgBkAcctType()       );
      contrOtherCustRow.setIntroChgBkAcctNumber(     contrOtherCustRow2.getIntroChgBkAcctNumber()     );
      contrOtherCustRow.setIntroChgBkAcctNameAlt(    contrOtherCustRow2.getIntroChgBkAcctNameAlt()    );
      contrOtherCustRow.setIntroChgBkAcctName(       contrOtherCustRow2.getIntroChgBkAcctName()       );
      contrOtherCustRow.setElectricBkChgBearer(      contrOtherCustRow2.getElectricBkChgBearer()      );
      contrOtherCustRow.setElectricBkNumber(         contrOtherCustRow2.getElectricBkNumber()         );
      contrOtherCustRow.setElectricBranchNumber(     contrOtherCustRow2.getElectricBranchNumber()     );
      contrOtherCustRow.setElectricBankName(         contrOtherCustRow2.getElectricBankName()         );
      contrOtherCustRow.setElectricBankBranchName(   contrOtherCustRow2.getElectricBankBranchName()   );
      contrOtherCustRow.setElectricBkAcctType(       contrOtherCustRow2.getElectricBkAcctType()       );
      contrOtherCustRow.setElectricBkAcctNumber(     contrOtherCustRow2.getElectricBkAcctNumber()     );
      contrOtherCustRow.setElectricBkAcctNameAlt(    contrOtherCustRow2.getElectricBkAcctNameAlt()    );
      contrOtherCustRow.setElectricBkAcctName(       contrOtherCustRow2.getElectricBkAcctName()       );

      // SP専決ヘッダサマリVOの初期化
      spDecHedSumVo.first();
      XxcsoSpDecisionHeadersSummuryVORowImpl spDecHedSumRow
        = (XxcsoSpDecisionHeadersSummuryVORowImpl) spDecHedSumVo.first();

      // // 契約先以外テーブルのデータが存在する場合
      if ( contrOtherCustRow != null )
      {
        // チェックボックスがチェックかつ、該当項目がNULLの場合は初期値を設定
        // 設置協賛金リージョン
        if( createRow.getInstSuppType() != null
             && createRow.getInstSuppType().equals(XxcsoContractRegistConstants.INST_SUPP_TYPE1))
        {
          // 振込手数料負担
          if(contrOtherCustRow.getInstallSuppBkChgBearer() == null)
          {
            contrOtherCustRow.setInstallSuppBkChgBearer("I");
          }
          // 口座種別
          if(contrOtherCustRow.getInstallSuppBkAcctType() == null)
          {
            contrOtherCustRow.setInstallSuppBkAcctType("1");
          }
        }
        // 紹介手数料リージョン
        if( createRow.getIntroChgType() != null
             && createRow.getIntroChgType().equals(XxcsoContractRegistConstants.INTRO_CHG_TYPE1))
        {
          // 振込手数料負担
          if(contrOtherCustRow.getIntroChgBkChgBearer() == null){
            contrOtherCustRow.setIntroChgBkChgBearer("I");
          }
          // 口座種別
          if(contrOtherCustRow.getIntroChgBkAcctType() == null)
          {
            contrOtherCustRow.setIntroChgBkAcctType("1");
          }
        }
        // 電気代リージョン
        if( createRow.getElectricPaymentType() != null
             && createRow.getElectricPaymentType().equals(XxcsoContractRegistConstants.ELECTRIC_PAYMENT_TYPE2))
        {
          // 振込手数料負担
          if(contrOtherCustRow.getElectricBkChgBearer() == null)
          {
            contrOtherCustRow.setElectricBkChgBearer("I");
          }
          // 口座種別
          if(contrOtherCustRow.getElectricBkAcctType() == null)
          {
            contrOtherCustRow.setElectricBkAcctType("1");
          }
        }
      }
    }
// 2015-02-02 [E_本稼動_12565] Add End
    XxcsoUtils.debug(txn, "[END]");
  }

}