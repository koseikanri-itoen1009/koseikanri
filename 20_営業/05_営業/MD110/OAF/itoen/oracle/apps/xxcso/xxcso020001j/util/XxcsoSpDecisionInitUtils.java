/*============================================================================
* ファイル名 : XxcsoSpDecisionCalculateUtils
* 概要説明   : SP専決初期化用ユーティリティクラス
* バージョン : 1.4
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩    新規作成
* 2009-05-25 1.1  SCS柳平直人  [ST障害T1_1136]LOVPK項目設定対応
* 2009-08-04 1.2  SCS小川浩     [SCS障害0000908]コピー時の回送先再設定対応
* 2013-04-19 1.3  SCSK桐生和幸 [E_本稼動_09603]契約書未確定による顧客区分遷移の変更対応
* 2014-01-31 1.4  SCSK桐生和幸 [E_本稼動_11397]売価1円対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.util;

import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleTypes;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.util.XxcsoSpDecisionConstants;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInitVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionHeaderFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionInstCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionCntrctCustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm1CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm2CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionBm3CustFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionScLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAllCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSelCcLineFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionAttachFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendFullVORowImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendInitVOImpl;
import itoen.oracle.apps.xxcso.xxcso020001j.server.XxcsoSpDecisionSendInitVORowImpl;
import java.sql.CallableStatement;
import java.sql.SQLException;
// 2009-05-25 [ST障害T1_1136] Add Start
import oracle.jbo.domain.Number;
// 2009-05-25 [ST障害T1_1136] Add End

/*******************************************************************************
 * SP専決書の各種初期化を行うためのユーティリティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionInitUtils 
{
  /*****************************************************************************
   * トランザクション初期化
   * @param txn                   OADBTransactionインスタンス
   * @param spDecisionHeaderId    SP専決ヘッダID
   * @param appBaseCode           申請拠点コード
   *****************************************************************************
   */
  public static void initializeTransaction(
    OADBTransaction  txn
   ,String           spDecisionHeaderId
   ,String           appBaseCode
  )
  {
    XxcsoUtils.debug(txn, "[START]");

    CallableStatement stmt = null;

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_020001j_pkg.initialize_transaction(");
    sql.append("    iv_sp_decision_header_id  => :1");
    sql.append("   ,iv_app_base_code          => :2");
    sql.append("   ,ov_errbuf                 => :3");
    sql.append("   ,ov_retcode                => :4");
    sql.append("   ,ov_errmsg                 => :5");
    sql.append(");");
    sql.append("END;");

    XxcsoUtils.debug(txn, "execute = " + sql.toString());
    
    try
    {
      stmt = txn.createCallableStatement(sql.toString(), 0);

      int index = 0;
      stmt.setString(++index, spDecisionHeaderId);
      stmt.setString(++index, appBaseCode);

      int outIndex = index;
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf  = stmt.getString(++outIndex);
      String retCode = stmt.getString(++outIndex);
      String errMsg  = stmt.getString(++outIndex);

      XxcsoUtils.debug(txn, "errbuf  = " + errBuf);
      XxcsoUtils.debug(txn, "retcode = " + retCode);
      XxcsoUtils.debug(txn, "errmsg  = " + errMsg);
      
      if ( ! "0".equals(retCode) )
      {
        XxcsoMessage.createCriticalErrorMessage(
          XxcsoConstants.TOKEN_VALUE_FULL_VD_SP_DECISION
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_INITIALIZE
         ,errBuf
        );
      }
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      XxcsoMessage.createSqlErrorMessage(
        e
       ,XxcsoConstants.TOKEN_VALUE_FULL_VD_SP_DECISION
          + XxcsoConstants.TOKEN_VALUE_DELIMITER1
          + XxcsoConstants.TOKEN_VALUE_INITIALIZE
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
    
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * 各行初期化
   * @param initVo        SP専決初期化用ビューインスタンス
   * @param sendInitVo    回送先初期化用ビューインスタンス
   * @param headerVo      SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo     設置先登録／更新用ビューインスタンス
   * @param cntrctVo      契約先登録／更新用ビューインスタンス
   * @param bm1Vo         BM1登録／更新用ビューインスタンス
   * @param bm2Vo         BM2登録／更新用ビューインスタンス
   * @param bm3Vo         BM3登録／更新用ビューインスタンス
   * @param sendVo        回送先登録／更新用ビューインスタンス
   *****************************************************************************
   */
  public static void initializeRow(
    XxcsoSpDecisionInitVOImpl           initVo
   ,XxcsoSpDecisionSendInitVOImpl       sendInitVo
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl   installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo
   ,XxcsoSpDecisionSendFullVOImpl       sendVo
  )
  {
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    
    ///////////////////////////////////////////
    // 新規作成処理
    ///////////////////////////////////////////
    // ヘッダ行を作成
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);
    
    // ヘッダ行の初期値を設定
    headerRow.setApplicationDate(initRow.getCurrentDate());
    headerRow.setAppBaseCode(initRow.getBaseCode());
    headerRow.setAppBaseName(initRow.getBaseName());
    headerRow.setStatus(XxcsoSpDecisionConstants.INIT_STATUS);
    headerRow.setApplicationCode(initRow.getEmployeeNumber());
    headerRow.setFullName(initRow.getFullName());
    headerRow.setApplicationType(XxcsoSpDecisionConstants.APP_TYPE_NEW);
    headerRow.setConstructionCharge(
      XxcsoSpDecisionConstants.INIT_CONSTRUCT_CHG
    );
    headerRow.setElectricityAmtMonth(
      XxcsoSpDecisionConstants.INIT_ELEC_CHG_MONTH
    );
    
    // 設置先行を作成
    installVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.createRow();

    installVo.insertRow(installRow);

    // 設置先行の初期値を設定
    installRow.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_INSTALL
    );

    // 契約先行を作成
    cntrctVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.createRow();

    cntrctVo.insertRow(cntrctRow);

    // 契約先行の初期値を設定
    cntrctRow.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_CNTRCT
    );
    
    // BM1行を作成
    bm1Vo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.createRow();

    bm1Vo.insertRow(bm1Row);

    // BM1行の初期値を設定
    bm1Row.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_BM1
    );
    bm1Row.setBmPaymentType(
      XxcsoSpDecisionConstants.INIT_BM1_PAY_CLASS
    );
    
    // BM2行を作成
    bm2Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.createRow();

    bm2Vo.insertRow(bm2Row);

    // BM2行の初期値を設定
    bm2Row.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_BM2
    );
    bm2Row.setBmPaymentType(
      XxcsoSpDecisionConstants.INIT_BM2_PAY_CLASS
    );
    
    // BM3行を作成
    bm3Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.createRow();

    bm3Vo.insertRow(bm3Row);

    // BM3行の初期値を設定
    bm3Row.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_BM3
    );
    bm3Row.setBmPaymentType(
      XxcsoSpDecisionConstants.INIT_BM3_PAY_CLASS
    );

    // 回送先のデフォルト値を取得
    XxcsoSpDecisionSendInitVORowImpl sendInitRow
      = (XxcsoSpDecisionSendInitVORowImpl)sendInitVo.first();

    while ( sendInitRow != null )
    {
      // 回送先行を作成
      XxcsoSpDecisionSendFullVORowImpl sendRow
        = (XxcsoSpDecisionSendFullVORowImpl)sendVo.createRow();

      sendVo.last();
      sendVo.next();
      sendVo.insertRow(sendRow);

      // 回送先行の初期値を設定
      sendRow.setApprovalAuthorityName(
        sendInitRow.getApprovalAuthorityName()
      );
      sendRow.setApprovalAuthorityNumber(
        sendInitRow.getApprovalAuthorityNumber()
      );
      sendRow.setApprovalTypeCode(
        sendInitRow.getApprovalTypeCode()
      );
      sendRow.setWorkRequestType(
        sendInitRow.getWorkRequestType()
      );
      sendRow.setRangeType(
        XxcsoSpDecisionConstants.INIT_RANGE_TYPE
      );
      sendRow.setApproveCode(
        XxcsoSpDecisionConstants.INIT_APPROVE_CODE
      );
      sendRow.setApprovalStateType(
        XxcsoSpDecisionConstants.APPR_NONE
      );
      sendRow.setApprAuthLevelNumber(
        sendInitRow.getApprAuthLevelNumber()
      );
// 2009-05-25 [ST障害T1_1136] Add Start
      sendRow.setApproveUserId(
        new Number(-1)
      );
// 2009-05-25 [ST障害T1_1136] Add Start

      sendInitRow = (XxcsoSpDecisionSendInitVORowImpl)sendInitVo.next();
    }
  }


  /*****************************************************************************
   * 各行初期化
   * @param initVo      SP専決初期化用ビューインスタンス
   * @param headerVo   （コピー先）SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo  （コピー先）設置先登録／更新用ビューインスタンス
   * @param cntrctVo   （コピー先）契約先登録／更新用ビューインスタンス
   * @param bm1Vo      （コピー先）BM1登録／更新用ビューインスタンス
   * @param bm2Vo      （コピー先）BM2登録／更新用ビューインスタンス
   * @param bm3Vo      （コピー先）BM3登録／更新用ビューインスタンス
   * @param scVo       （コピー先）売価別条件登録／更新用ビューインスタンス
   * @param allCcVo    （コピー先）全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo    （コピー先）容器別条件登録／更新用ビューインスタンス
   * @param attachVo   （コピー先）添付登録／更新用ビューインスタンス
   * @param sendVo     （コピー先）回送先登録／更新用ビューインスタンス
   * @param headerVo2  （コピー元）SP専決ヘッダ登録／更新用ビューインスタンス
   * @param installVo2 （コピー元）設置先登録／更新用ビューインスタンス
   * @param cntrctVo2  （コピー元）契約先登録／更新用ビューインスタンス
   * @param bm1Vo2     （コピー元）BM1登録／更新用ビューインスタンス
   * @param bm2Vo2     （コピー元）BM2登録／更新用ビューインスタンス
   * @param bm3Vo2     （コピー元）BM3登録／更新用ビューインスタンス
   * @param scVo2      （コピー元）売価別条件登録／更新用ビューインスタンス
   * @param allCcVo2   （コピー元）全容器一律条件登録／更新用ビューインスタンス
   * @param selCcVo2   （コピー元）容器別条件登録／更新用ビューインスタンス
   * @param attachVo2  （コピー元）添付登録／更新用ビューインスタンス
   * @param sendVo2    （コピー元）回送先登録／更新用ビューインスタンス
   * @param sendInitVo  回送先初期化用ビューインスタンス
   *****************************************************************************
   */
  public static void initializeCopyRow(
    XxcsoSpDecisionInitVOImpl           initVo
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo
   ,XxcsoSpDecisionInstCustFullVOImpl   installVo
   ,XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo
   ,XxcsoSpDecisionScLineFullVOImpl     scVo
   ,XxcsoSpDecisionAllCcLineFullVOImpl  allCcVo
   ,XxcsoSpDecisionSelCcLineFullVOImpl  selCcVo
   ,XxcsoSpDecisionAttachFullVOImpl     attachVo
   ,XxcsoSpDecisionSendFullVOImpl       sendVo
   ,XxcsoSpDecisionHeaderFullVOImpl     headerVo2
   ,XxcsoSpDecisionInstCustFullVOImpl   installVo2
   ,XxcsoSpDecisionCntrctCustFullVOImpl cntrctVo2
   ,XxcsoSpDecisionBm1CustFullVOImpl    bm1Vo2
   ,XxcsoSpDecisionBm2CustFullVOImpl    bm2Vo2
   ,XxcsoSpDecisionBm3CustFullVOImpl    bm3Vo2
   ,XxcsoSpDecisionScLineFullVOImpl     scVo2
   ,XxcsoSpDecisionAllCcLineFullVOImpl  allCcVo2
   ,XxcsoSpDecisionSelCcLineFullVOImpl  selCcVo2
   ,XxcsoSpDecisionAttachFullVOImpl     attachVo2
   ,XxcsoSpDecisionSendFullVOImpl       sendVo2
// 2009-08-04 [障害0000908] Add Start
   ,XxcsoSpDecisionSendInitVOImpl       sendInitVo
// 2009-08-04 [障害0000908] Add End
  )
  {
    XxcsoSpDecisionInitVORowImpl initRow
      = (XxcsoSpDecisionInitVORowImpl)initVo.first();
    
    ///////////////////////////////////////////
    // 新規作成処理
    ///////////////////////////////////////////
    // ヘッダ行を作成
    XxcsoSpDecisionHeaderFullVORowImpl headerRow
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo.createRow();

    headerVo.insertRow(headerRow);
    
    // ヘッダ行の初期値を設定
    headerRow.setApplicationDate(initRow.getCurrentDate());
    headerRow.setAppBaseCode(initRow.getBaseCode());
    headerRow.setAppBaseName(initRow.getBaseName());
    headerRow.setStatus(XxcsoSpDecisionConstants.INIT_STATUS);
    headerRow.setApplicationCode(initRow.getEmployeeNumber());
    headerRow.setFullName(initRow.getFullName());
    headerRow.setApplicationType(XxcsoSpDecisionConstants.APP_TYPE_MOD);

    // ヘッダ行のコピー
    XxcsoSpDecisionHeaderFullVORowImpl headerRow2
      = (XxcsoSpDecisionHeaderFullVORowImpl)headerVo2.first();
    headerRow.setNewoldType(            headerRow2.getNewoldType()            );
    headerRow.setSeleNumber(            headerRow2.getSeleNumber()            );
    headerRow.setMakerCode(             headerRow2.getMakerCode()             );
    headerRow.setStandardType(          headerRow2.getStandardType()          );
    headerRow.setUnNumber(              headerRow2.getUnNumber()              );
// 2009-05-25 [ST障害T1_1136] Add Start
    headerRow.setUnNumberId(            headerRow2.getUnNumberId()            );
// 2009-05-25 [ST障害T1_1136] Add End
    headerRow.setInstallDate(           headerRow2.getInstallDate()           );
    headerRow.setLeaseCompany(          headerRow2.getLeaseCompany()          );
    headerRow.setConditionBusinessType( headerRow2.getConditionBusinessType() );
    headerRow.setAllContainerType(      headerRow2.getAllContainerType()      );
    headerRow.setContractYearDate(      headerRow2.getContractYearDate()      );
    headerRow.setInstallSupportAmt(     headerRow2.getInstallSupportAmt()     );
    headerRow.setInstallSupportAmt2(    headerRow2.getInstallSupportAmt2()    );
    headerRow.setPaymentCycle(          headerRow2.getPaymentCycle()          );
    headerRow.setElectricityType(       headerRow2.getElectricityType()       );
    headerRow.setElectricityAmount(     headerRow2.getElectricityAmount()     );
    headerRow.setConditionReason(       headerRow2.getConditionReason()       );
    headerRow.setBm1SendType(           headerRow2.getBm1SendType()           );
    headerRow.setOtherContent(          headerRow2.getOtherContent()          );
    headerRow.setSalesMonth(            headerRow2.getSalesMonth()            );
    headerRow.setSalesYear(             headerRow2.getSalesYear()             );
    headerRow.setSalesGrossMarginRate(  headerRow2.getSalesGrossMarginRate()  );
    headerRow.setYearGrossMarginAmt(    headerRow2.getYearGrossMarginAmt()    );
    headerRow.setBmRate(                headerRow2.getBmRate()                );
    headerRow.setVdSalesCharge(         headerRow2.getVdSalesCharge()         );
    headerRow.setInstallSupportAmtYear( headerRow2.getInstallSupportAmtYear() );
    headerRow.setLeaseChargeMonth(      headerRow2.getLeaseChargeMonth()      );
    headerRow.setConstructionCharge(    headerRow2.getConstructionCharge()    );
    headerRow.setVdLeaseCharge(         headerRow2.getVdLeaseCharge()         );
    headerRow.setElectricityAmtMonth(   headerRow2.getElectricityAmtMonth()   );
    headerRow.setElectricityAmtYear(    headerRow2.getElectricityAmtYear()    );
    headerRow.setTransportationCharge(  headerRow2.getTransportationCharge()  );
    headerRow.setLaborCostOther(        headerRow2.getLaborCostOther()        );
    headerRow.setTotalCost(             headerRow2.getTotalCost()             );
    headerRow.setOperatingProfit(       headerRow2.getOperatingProfit()       );
    headerRow.setOperatingProfitRate(   headerRow2.getOperatingProfitRate()   );
    headerRow.setBreakEvenPoint(        headerRow2.getBreakEvenPoint()        );
    headerRow.setContractYearDateView(  headerRow2.getContractYearDateView()  );
    headerRow.setElectricityType(       headerRow2.getElectricityTypeView()   );
    headerRow.setElectricityAmountView( headerRow2.getElectricityAmountView() );
    headerRow.setInstallSupportAmtView( headerRow2.getInstallSupportAmtView() );
    headerRow.setPaymentCycleView(      headerRow2.getPaymentCycleView()      );
    headerRow.setInstallSupportAmt2View(headerRow2.getInstallSupportAmt2View());
    
    // 設置先行を作成
    installVo.first();
    XxcsoSpDecisionInstCustFullVORowImpl installRow
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo.createRow();

    installVo.insertRow(installRow);

    // 設置先行の初期値を設定
    installRow.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_INSTALL
    );

    // 設置先行のコピー
    XxcsoSpDecisionInstCustFullVORowImpl installRow2
      = (XxcsoSpDecisionInstCustFullVORowImpl)installVo2.first();
    installRow.setInstallAccountNumber( installRow2.getInstallAccountNumber() );
    installRow.setPartyName(            installRow2.getPartyName()            );
    installRow.setPartyNameAlt(         installRow2.getPartyNameAlt()         );
    installRow.setInstallName(          installRow2.getInstallName()          );
    installRow.setPostalCodeFirst(      installRow2.getPostalCodeFirst()      );
    installRow.setPostalCodeSecond(     installRow2.getPostalCodeSecond()     );
    installRow.setState(                installRow2.getState()                );
    installRow.setCity(                 installRow2.getCity()                 );
    installRow.setAddress1(             installRow2.getAddress1()             );
    installRow.setAddress2(             installRow2.getAddress2()             );
    installRow.setAddressLinesPhonetic( installRow2.getAddressLinesPhonetic() );
    installRow.setBusinessConditionType(installRow2.getBusinessConditionType());
    installRow.setBusinessType(         installRow2.getBusinessType()         );
    installRow.setInstallLocation(      installRow2.getInstallLocation()      );
    installRow.setExternalReferenceOpclType(
      installRow2.getExternalReferenceOpclType()
    );
    installRow.setEmployeeNumber(       installRow2.getEmployeeNumber()       );
    installRow.setPublishBaseCode(      installRow2.getPublishBaseCode()      );
    installRow.setPublishBaseName(      installRow2.getPublishBaseName()      );
    installRow.setCustomerId(           installRow2.getCustomerId()           );
    installRow.setCustomerStatus(       installRow2.getCustomerStatus()       );
    installRow.setPublishBaseCodeView(  installRow2.getPublishBaseCodeView()  );
    installRow.setPublishBaseNameView(  installRow2.getPublishBaseNameView()  );
// 2013-04-19 [E_本稼動_09603] Add Start
    installRow.setUpdateCustEnable(     installRow2.getUpdateCustEnable()     );
// 2013-04-19 [E_本稼動_09603] Add End
    // 契約先行を作成
    cntrctVo.first();
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo.createRow();

    cntrctVo.insertRow(cntrctRow);

    // 契約先行の初期値を設定
    cntrctRow.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_CNTRCT
    );
    
    // 設置先行のコピー
    XxcsoSpDecisionCntrctCustFullVORowImpl cntrctRow2
      = (XxcsoSpDecisionCntrctCustFullVORowImpl)cntrctVo2.first();
    cntrctRow.setSameInstallAccountFlag(
      cntrctRow2.getSameInstallAccountFlag()
    );
    cntrctRow.setContractNumber(       cntrctRow2.getContractNumber()       );
    cntrctRow.setPartyName(            cntrctRow2.getPartyName()            );
    cntrctRow.setPartyNameAlt(         cntrctRow2.getPartyNameAlt()         );
    cntrctRow.setPostalCodeFirst(      cntrctRow2.getPostalCodeFirst()      );
    cntrctRow.setPostalCodeSecond(     cntrctRow2.getPostalCodeSecond()     );
    cntrctRow.setState(                cntrctRow2.getState()                );
    cntrctRow.setCity(                 cntrctRow2.getCity()                 );
    cntrctRow.setAddress1(             cntrctRow2.getAddress1()             );
    cntrctRow.setAddress2(             cntrctRow2.getAddress2()             );
    cntrctRow.setAddressLinesPhonetic( cntrctRow2.getAddressLinesPhonetic() );
    cntrctRow.setRepresentativeName(   cntrctRow2.getRepresentativeName()   );
    cntrctRow.setCustomerId(           cntrctRow2.getCustomerId()           );

    // 売価別条件のコピー
    scVo.first();
    XxcsoSpDecisionScLineFullVORowImpl scRow2
      = (XxcsoSpDecisionScLineFullVORowImpl)scVo2.first();
    while ( scRow2 != null )
    {
      XxcsoSpDecisionScLineFullVORowImpl scRow
        = (XxcsoSpDecisionScLineFullVORowImpl)scVo.createRow();
      scVo.last();
      scVo.next();
      scVo.insertRow(scRow);
      scRow.setFixedPrice(              scRow2.getFixedPrice()              );
// 2014-01-31 [E_本稼動_11397] Add Start
      scRow.setCardSaleClass(           scRow2.getCardSaleClass()           );
// 2014-01-31 [E_本稼動_11397] Add End
      scRow.setSalesPrice(              scRow2.getSalesPrice()              );
      scRow.setBmRatePerSalesPrice(     scRow2.getBmRatePerSalesPrice()     );
      scRow.setBmAmountPerSalesPrice(   scRow2.getBmAmountPerSalesPrice()   );
      scRow.setBmConvRatePerSalesPrice( scRow2.getBmConvRatePerSalesPrice() );
      scRow.setBm1BmRate(               scRow2.getBm1BmRate()               );
      scRow.setBm1BmAmount(             scRow2.getBm1BmAmount()             );
      scRow.setBm2BmRate(               scRow2.getBm2BmRate()               );
      scRow.setBm2BmAmount(             scRow2.getBm2BmAmount()             );
      scRow.setBm3BmRate(               scRow2.getBm3BmRate()               );
      scRow.setBm3BmAmount(             scRow2.getBm3BmAmount()             );

      scRow2 = (XxcsoSpDecisionScLineFullVORowImpl)scVo2.next();
    }

    // 全容器一律条件のコピー
    allCcVo.first();
    XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow2
      = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo2.first();
    while ( allCcRow2 != null )
    {
      XxcsoSpDecisionAllCcLineFullVORowImpl allCcRow
        = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo.createRow();
      allCcVo.last();
      allCcVo.next();
      allCcVo.insertRow(allCcRow);
      allCcRow.setSpContainerType(         allCcRow2.getSpContainerType()     );
      allCcRow.setDiscountAmt(             allCcRow2.getDiscountAmt()         );
      allCcRow.setDefinedFixedPrice(       allCcRow2.getDefinedFixedPrice()   );
      allCcRow.setDefinedCostRate(         allCcRow2.getDefinedCostRate()     );
      allCcRow.setCostPrice(               allCcRow2.getCostPrice()           );
      allCcRow.setBmRatePerSalesPrice(     allCcRow2.getBmRatePerSalesPrice() );
      allCcRow.setBmAmountPerSalesPrice(
        allCcRow2.getBmAmountPerSalesPrice()
      );
      allCcRow.setBmConvRatePerSalesPrice(
        allCcRow2.getBmConvRatePerSalesPrice()
      );
      allCcRow.setBm1BmRate(               allCcRow2.getBm1BmRate()           );
      allCcRow.setBm1BmAmount(             allCcRow2.getBm1BmAmount()         );
      allCcRow.setBm2BmRate(               allCcRow2.getBm2BmRate()           );
      allCcRow.setBm2BmAmount(             allCcRow2.getBm2BmAmount()         );
      allCcRow.setBm3BmRate(               allCcRow2.getBm3BmRate()           );
      allCcRow.setBm3BmAmount(             allCcRow2.getBm3BmAmount()         );

      allCcRow2 = (XxcsoSpDecisionAllCcLineFullVORowImpl)allCcVo2.next();
    }

    // 容器別条件のコピー
    selCcVo.first();
    XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow2
      = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo2.first();
    while ( selCcRow2 != null )
    {
      XxcsoSpDecisionSelCcLineFullVORowImpl selCcRow
        = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo.createRow();
      selCcVo.last();
      selCcVo.next();
      selCcVo.insertRow(selCcRow);
      selCcRow.setSpContainerType(         selCcRow2.getSpContainerType()     );
      selCcRow.setDiscountAmt(             selCcRow2.getDiscountAmt()         );
      selCcRow.setDefinedFixedPrice(       selCcRow2.getDefinedFixedPrice()   );
      selCcRow.setDefinedCostRate(         selCcRow2.getDefinedCostRate()     );
      selCcRow.setCostPrice(               selCcRow2.getCostPrice()           );
      selCcRow.setBmRatePerSalesPrice(     selCcRow2.getBmRatePerSalesPrice() );
      selCcRow.setBmAmountPerSalesPrice(
        selCcRow2.getBmAmountPerSalesPrice()
      );
      selCcRow.setBmConvRatePerSalesPrice(
        selCcRow2.getBmConvRatePerSalesPrice()
      );
      selCcRow.setBm1BmRate(               selCcRow2.getBm1BmRate()           );
      selCcRow.setBm1BmAmount(             selCcRow2.getBm1BmAmount()         );
      selCcRow.setBm2BmRate(               selCcRow2.getBm2BmRate()           );
      selCcRow.setBm2BmAmount(             selCcRow2.getBm2BmAmount()         );
      selCcRow.setBm3BmRate(               selCcRow2.getBm3BmRate()           );
      selCcRow.setBm3BmAmount(             selCcRow2.getBm3BmAmount()         );

      selCcRow2 = (XxcsoSpDecisionSelCcLineFullVORowImpl)selCcVo2.next();
    }

    // BM1行を作成
    bm1Vo.first();
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo.createRow();

    bm1Vo.insertRow(bm1Row);

    // BM1行の初期値を設定
    bm1Row.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_BM1
    );

    // BM1行のコピー
    XxcsoSpDecisionBm1CustFullVORowImpl bm1Row2
      = (XxcsoSpDecisionBm1CustFullVORowImpl)bm1Vo2.first();
    bm1Row.setVendorNumber(           bm1Row2.getVendorNumber()           );
    bm1Row.setPartyName(              bm1Row2.getPartyName()              );
    bm1Row.setPartyNameAlt(           bm1Row2.getPartyNameAlt()           );
    bm1Row.setPostalCodeFirst(        bm1Row2.getPostalCodeFirst()        );
    bm1Row.setPostalCodeSecond(       bm1Row2.getPostalCodeSecond()       );
    bm1Row.setState(                  bm1Row2.getState()                  );
    bm1Row.setCity(                   bm1Row2.getCity()                   );
    bm1Row.setAddress1(               bm1Row2.getAddress1()               );
    bm1Row.setAddress2(               bm1Row2.getAddress2()               );
    bm1Row.setAddressLinesPhonetic(   bm1Row2.getAddressLinesPhonetic()   );
    bm1Row.setTransferCommissionType( bm1Row2.getTransferCommissionType() );
    bm1Row.setBmPaymentType(          bm1Row2.getBmPaymentType()          );
    bm1Row.setInquiryBaseCode(        bm1Row2.getInquiryBaseCode()        );
    bm1Row.setInquiryBaseName(        bm1Row2.getInquiryBaseName()        );
    bm1Row.setCustomerId(             bm1Row2.getCustomerId()             );
    bm1Row.setTransferCommissionTypeView(
      bm1Row2.getTransferCommissionTypeView()
    );
    
    // BM2行を作成
    bm2Vo.first();
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo.createRow();

    bm2Vo.insertRow(bm2Row);

    // BM2行の初期値を設定
    bm2Row.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_BM2
    );

    // BM2行のコピー
    XxcsoSpDecisionBm2CustFullVORowImpl bm2Row2
      = (XxcsoSpDecisionBm2CustFullVORowImpl)bm2Vo2.first();
    bm2Row.setVendorNumber(           bm2Row2.getVendorNumber()           );
    bm2Row.setPartyName(              bm2Row2.getPartyName()              );
    bm2Row.setPartyNameAlt(           bm2Row2.getPartyNameAlt()           );
    bm2Row.setPostalCodeFirst(        bm2Row2.getPostalCodeFirst()        );
    bm2Row.setPostalCodeSecond(       bm2Row2.getPostalCodeSecond()       );
    bm2Row.setState(                  bm2Row2.getState()                  );
    bm2Row.setCity(                   bm2Row2.getCity()                   );
    bm2Row.setAddress1(               bm2Row2.getAddress1()               );
    bm2Row.setAddress2(               bm2Row2.getAddress2()               );
    bm2Row.setAddressLinesPhonetic(   bm2Row2.getAddressLinesPhonetic()   );
    bm2Row.setTransferCommissionType( bm2Row2.getTransferCommissionType() );
    bm2Row.setBmPaymentType(          bm2Row2.getBmPaymentType()          );
    bm2Row.setInquiryBaseCode(        bm2Row2.getInquiryBaseCode()        );
    bm2Row.setInquiryBaseName(        bm2Row2.getInquiryBaseName()        );
    bm2Row.setCustomerId(             bm2Row2.getCustomerId()             );
    
    // BM3行を作成
    bm3Vo.first();
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo.createRow();

    bm3Vo.insertRow(bm3Row);

    // BM3行の初期値を設定
    bm3Row.setSpDecisionCustomerClass(
      XxcsoSpDecisionConstants.CUST_CLASS_BM3
    );

    // BM3行のコピー
    XxcsoSpDecisionBm3CustFullVORowImpl bm3Row2
      = (XxcsoSpDecisionBm3CustFullVORowImpl)bm3Vo2.first();
    bm3Row.setVendorNumber(           bm3Row2.getVendorNumber()           );
    bm3Row.setPartyName(              bm3Row2.getPartyName()              );
    bm3Row.setPartyNameAlt(           bm3Row2.getPartyNameAlt()           );
    bm3Row.setPostalCodeFirst(        bm3Row2.getPostalCodeFirst()        );
    bm3Row.setPostalCodeSecond(       bm3Row2.getPostalCodeSecond()       );
    bm3Row.setState(                  bm3Row2.getState()                  );
    bm3Row.setCity(                   bm3Row2.getCity()                   );
    bm3Row.setAddress1(               bm3Row2.getAddress1()               );
    bm3Row.setAddress2(               bm3Row2.getAddress2()               );
    bm3Row.setAddressLinesPhonetic(   bm3Row2.getAddressLinesPhonetic()   );
    bm3Row.setTransferCommissionType( bm3Row2.getTransferCommissionType() );
    bm3Row.setBmPaymentType(          bm3Row2.getBmPaymentType()          );
    bm3Row.setInquiryBaseCode(        bm3Row2.getInquiryBaseCode()        );
    bm3Row.setInquiryBaseName(        bm3Row2.getInquiryBaseName()        );
    bm3Row.setCustomerId(             bm3Row2.getCustomerId()             );

    // 添付のコピー
    attachVo.first();
    XxcsoSpDecisionAttachFullVORowImpl attachRow2
      = (XxcsoSpDecisionAttachFullVORowImpl)attachVo2.first();
    while ( attachRow2 != null )
    {
      XxcsoSpDecisionAttachFullVORowImpl attachRow
        = (XxcsoSpDecisionAttachFullVORowImpl)attachVo.createRow();
      attachVo.last();
      attachVo.next();
      attachVo.insertRow(attachRow);
      attachRow.setFileName  (attachRow2.getFileName() );
      attachRow.setFileData  (attachRow2.getFileData() );
      attachRow.setExcerpt(  attachRow2.getExcerpt()   );

      attachRow2 = (XxcsoSpDecisionAttachFullVORowImpl)attachVo2.next();
    }

    // 回送先のコピー
// 2009-08-04 [障害0000908] Mod Start
//    sendVo.first();
//    XxcsoSpDecisionSendFullVORowImpl sendRow2
//      = (XxcsoSpDecisionSendFullVORowImpl)sendVo2.first();
//    while ( sendRow2 != null )
//    {
//      XxcsoSpDecisionSendFullVORowImpl sendRow
//        = (XxcsoSpDecisionSendFullVORowImpl)sendVo.createRow();
//      sendVo.last();
//      sendVo.next();
//      sendVo.insertRow(sendRow);
//      sendRow.setApprovalTypeCode(       sendRow2.getApprovalTypeCode()       );
//      sendRow.setApprAuthLevelNumber(    sendRow2.getApprAuthLevelNumber()    );
//      sendRow.setApprovalAuthorityName(  sendRow2.getApprovalAuthorityName()  );
//      sendRow.setApprovalAuthorityNumber(sendRow2.getApprovalAuthorityNumber());
//      sendRow.setRangeType(              sendRow2.getRangeType()              );
//      sendRow.setApproveCode(            sendRow2.getApproveCode()            );
//      sendRow.setWorkRequestType(        sendRow2.getWorkRequestType()        );
//      sendRow.setApprovalStateType(XxcsoSpDecisionConstants.APPR_NONE);
//      sendRow.setApproveBaseShortName(   sendRow2.getApproveBaseShortName()   );
//      sendRow.setApproveUserName(        sendRow2.getApproveUserName()        );
//// 2009-05-25 [ST障害T1_1136] Add Start
//      sendRow.setApproveUserId(          sendRow2.getApproveUserId()          );
//// 2009-05-25 [ST障害T1_1136] Add End
//
//      sendRow2 = (XxcsoSpDecisionSendFullVORowImpl)sendVo2.next();
//    }

    // 回送先のデフォルト値を取得
    XxcsoSpDecisionSendInitVORowImpl sendInitRow
      = (XxcsoSpDecisionSendInitVORowImpl)sendInitVo.first();

    while ( sendInitRow != null )
    {
      // 回送先行を作成
      XxcsoSpDecisionSendFullVORowImpl sendRow
        = (XxcsoSpDecisionSendFullVORowImpl)sendVo.createRow();

      sendVo.last();
      sendVo.next();
      sendVo.insertRow(sendRow);

      // 回送先行の初期値を設定
      sendRow.setApprovalAuthorityName(
        sendInitRow.getApprovalAuthorityName()
      );
      sendRow.setApprovalAuthorityNumber(
        sendInitRow.getApprovalAuthorityNumber()
      );
      sendRow.setApprovalTypeCode(
        sendInitRow.getApprovalTypeCode()
      );
      sendRow.setWorkRequestType(
        sendInitRow.getWorkRequestType()
      );
      sendRow.setRangeType(
        XxcsoSpDecisionConstants.INIT_RANGE_TYPE
      );
      sendRow.setApproveCode(
        XxcsoSpDecisionConstants.INIT_APPROVE_CODE
      );
      sendRow.setApprovalStateType(
        XxcsoSpDecisionConstants.APPR_NONE
      );
      sendRow.setApprAuthLevelNumber(
        sendInitRow.getApprAuthLevelNumber()
      );
     sendRow.setApproveUserId(
        new Number(-1)
      );

      sendInitRow = (XxcsoSpDecisionSendInitVORowImpl)sendInitVo.next();
    }
// 2009-08-04 [障害0000908] Mod End
  }
}