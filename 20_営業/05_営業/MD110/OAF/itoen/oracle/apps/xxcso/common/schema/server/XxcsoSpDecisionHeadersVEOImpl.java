/*============================================================================
* ファイル名 : XxcsoSpDecisionHeadersVEOImpl
* 概要説明   : SP専決ヘッダエンティティクラス
* バージョン : 1.2
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS小川浩     新規作成
* 2009-04-02 1.1  SCS柳平直人   [ST障害T1-0229]SP専決ヘッダID採番方式修正
* 2014-12-15 1.2  SCSK桐生和幸  [E_本稼動_12565]SP・契約書画面改修対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.AttributeList;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoCustomDmlExecUtils;
import java.sql.SQLException;
import oracle.jbo.RowIterator;
import oracle.jdbc.OracleCallableStatement;
import oracle.jdbc.OracleTypes;

/*******************************************************************************
 * SP専決ヘッダのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionHeadersVEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SPDECISIONHEADERID = 0;
  protected static final int SPDECISIONNUMBER = 1;
  protected static final int SPDECISIONTYPE = 2;
  protected static final int STATUS = 3;
  protected static final int APPLICATIONNUMBER = 4;
  protected static final int APPLICATIONDATE = 5;
  protected static final int APPROVALCOMPLETEDATE = 6;
  protected static final int APPLICATIONCODE = 7;
  protected static final int APPBASECODE = 8;
  protected static final int APPLICATIONTYPE = 9;
  protected static final int NEWOLDTYPE = 10;
  protected static final int SELENUMBER = 11;
  protected static final int MAKERCODE = 12;
  protected static final int STANDARDTYPE = 13;
  protected static final int UNNUMBER = 14;
  protected static final int INSTALLDATE = 15;
  protected static final int LEASECOMPANY = 16;
  protected static final int CONDITIONBUSINESSTYPE = 17;
  protected static final int ALLCONTAINERTYPE = 18;
  protected static final int CONTRACTYEARDATE = 19;
  protected static final int INSTALLSUPPORTAMT = 20;
  protected static final int INSTALLSUPPORTAMT2 = 21;
  protected static final int PAYMENTCYCLE = 22;
  protected static final int ELECTRICITYTYPE = 23;
  protected static final int ELECTRICITYAMOUNT = 24;
  protected static final int CONDITIONREASON = 25;
  protected static final int BM1SENDTYPE = 26;
  protected static final int OTHERCONTENT = 27;
  protected static final int SALESMONTH = 28;
  protected static final int SALESYEAR = 29;
  protected static final int SALESGROSSMARGINRATE = 30;
  protected static final int YEARGROSSMARGINAMT = 31;
  protected static final int BMRATE = 32;
  protected static final int VDSALESCHARGE = 33;
  protected static final int INSTALLSUPPORTAMTYEAR = 34;
  protected static final int LEASECHARGEMONTH = 35;
  protected static final int CONSTRUCTIONCHARGE = 36;
  protected static final int VDLEASECHARGE = 37;
  protected static final int ELECTRICITYAMTMONTH = 38;
  protected static final int ELECTRICITYAMTYEAR = 39;
  protected static final int TRANSPORTATIONCHARGE = 40;
  protected static final int LABORCOSTOTHER = 41;
  protected static final int TOTALCOST = 42;
  protected static final int OPERATINGPROFIT = 43;
  protected static final int OPERATINGPROFITRATE = 44;
  protected static final int BREAKEVENPOINT = 45;
  protected static final int CREATEDBY = 46;
  protected static final int CREATIONDATE = 47;
  protected static final int LASTUPDATEDBY = 48;
  protected static final int LASTUPDATEDATE = 49;
  protected static final int LASTUPDATELOGIN = 50;
  protected static final int REQUESTID = 51;
  protected static final int PROGRAMAPPLICATIONID = 52;
  protected static final int PROGRAMID = 53;
  protected static final int PROGRAMUPDATEDATE = 54;
  protected static final int CONTRACTYEARMONTH = 55;
  protected static final int CONTRACTSTARTYEAR = 56;
  protected static final int CONTRACTSTARTMONTH = 57;
  protected static final int CONTRACTENDYEAR = 58;
  protected static final int CONTRACTENDMONTH = 59;
  protected static final int BIDDINGITEM = 60;
  protected static final int CANCELLBEFOREMATURITY = 61;
  protected static final int ADASSETSTYPE = 62;
  protected static final int ADASSETSAMT = 63;
  protected static final int ADASSETSTHISTIME = 64;
  protected static final int ADASSETSPAYMENTYEAR = 65;
  protected static final int ADASSETSPAYMENTDATE = 66;
  protected static final int TAXTYPE = 67;
  protected static final int INSTALLSUPPTYPE = 68;
  protected static final int INSTALLSUPPPAYMENTTYPE = 69;
  protected static final int INSTALLSUPPAMT = 70;
  protected static final int INSTALLSUPPTHISTIME = 71;
  protected static final int INSTALLSUPPPAYMENTYEAR = 72;
  protected static final int INSTALLSUPPPAYMENTDATE = 73;
  protected static final int ELECTRICPAYMENTTYPE = 74;
  protected static final int ELECTRICPAYMENTCHANGETYPE = 75;
  protected static final int ELECTRICPAYMENTCYCLE = 76;
  protected static final int ELECTRICCLOSINGDATE = 77;
  protected static final int ELECTRICTRANSMONTH = 78;
  protected static final int ELECTRICTRANSDATE = 79;
  protected static final int ELECTRICTRANSNAME = 80;
  protected static final int ELECTRICTRANSNAMEALT = 81;
  protected static final int INTROCHGTYPE = 82;
  protected static final int INTROCHGPAYMENTTYPE = 83;
  protected static final int INTROCHGAMT = 84;
  protected static final int INTROCHGTHISTIME = 85;
  protected static final int INTROCHGPAYMENTYEAR = 86;
  protected static final int INTROCHGPAYMENTDATE = 87;
  protected static final int INTROCHGPERSALESPRICE = 88;
  protected static final int INTROCHGPERPIECE = 89;
  protected static final int INTROCHGCLOSINGDATE = 90;
  protected static final int INTROCHGTRANSMONTH = 91;
  protected static final int INTROCHGTRANSDATE = 92;
  protected static final int INTROCHGTRANSNAME = 93;
  protected static final int INTROCHGTRANSNAMEALT = 94;
  protected static final int XXCSOSPDECISIONATTACHESEO = 95;
  protected static final int XXCSOSPDECISIONCUSTSVEO = 96;
  protected static final int XXCSOSPDECISIONLINESVEO = 97;
  protected static final int XXCSOSPDECISIONSENDSEO = 98;












































































  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionHeadersVEOImpl()
  {
  }

  /**
   * 
   * Retrieves the definition object for this instance class.
   */
  public static synchronized EntityDefImpl getDefinitionObject()
  {
    if (mDefinitionObject == null)
    {
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionHeadersVEO");
    }
    return mDefinitionObject;
  }











































































  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    super.create(list);
    
    setSpDecisionHeaderId(new Number(-1));
    setSpDecisionType("1");
    setStatus("1");
    setApplicationNumber(new Number(0));
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコードロック処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    StringBuffer sql = new StringBuffer(100);
    sql.append("BEGIN");
    sql.append("  xxcso_020001j_pkg.process_lock(");
    sql.append("    in_sp_decision_header_id => :1");
    sql.append("   ,iv_sp_decision_number    => :2");
    sql.append("   ,id_last_update_date      => :3");
    sql.append("   ,ov_errbuf                => :4");
    sql.append("   ,ov_retcode               => :5");
    sql.append("   ,ov_errmsg                => :6");
    sql.append("  );");
    sql.append("END;");

    OracleCallableStatement stmt = null;

    try
    {
      stmt
        = (OracleCallableStatement)
            txn.createCallableStatement(sql.toString(), 0);

      stmt.setNUMBER(1, getSpDecisionHeaderId());
      stmt.setString(2, getSpDecisionNumber());
      stmt.setDATE(3, getLastUpdateDate());
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);
      stmt.registerOutParameter(6, OracleTypes.VARCHAR);

      stmt.execute();

      String errbuf  = stmt.getString(4);
      String retcode = stmt.getString(5);
      String errmsg  = stmt.getString(6);

      if ( ! "0".equals(retcode) )
      {
        if ( XxcsoConstants.APP_XXCSO1_00002.equals(errmsg) )
        {
          throw XxcsoMessage.createTransactionLockError(
            XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM
            + getSpDecisionNumber()
          );
        }
        else if ( XxcsoConstants.APP_XXCSO1_00003.equals(errmsg) )
        {
          throw XxcsoMessage.createTransactionInconsistentError(
            XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM
            + getSpDecisionNumber()
          );
        }
        else
        {
          throw XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM
            + getSpDecisionNumber()
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_REGIST
           ,errmsg
          );
        }
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw XxcsoMessage.createSqlErrorMessage(
        sqle
       ,XxcsoConstants.TOKEN_VALUE_SP_DECISION_NUM
        + getSpDecisionNumber()
        + XxcsoConstants.TOKEN_VALUE_DELIMITER1
        + XxcsoConstants.TOKEN_VALUE_REGIST
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
      catch ( SQLException sqle )
      {
        XxcsoUtils.unexpected(txn, sqle);
      }
    }
    
    XxcsoUtils.debug(txn, "[END]");    
  }


  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

// 2009-04-02 [ST障害T1-0229] Mod Start
//    // 登録する直前でシーケンス値を払い出します。
//    Number spDecisionHeaderId
//      = getOADBTransaction().getSequenceValue("XXCSO_SP_DECISION_HEADERS_S01");
    Number spDecisionHeaderId = getSpDecisionHeaderId();
    if (spDecisionHeaderId.intValue() < 0)
    {
      spDecisionHeaderId
        = getOADBTransaction()
            .getSequenceValue("XXCSO_SP_DECISION_HEADERS_S01");

      XxcsoUtils.debug(
        txn
       ,"SP_DECISION_HEADER_ID:getSequence[" + spDecisionHeaderId + "]"
      );

    }
// 2009-04-02 [ST障害T1-0229] Mod End

    setSpDecisionHeaderId(spDecisionHeaderId);
    setSpDecisionNumber(spDecisionHeaderId.toString());

    replaceNumber();
    
    try
    {
      XxcsoCustomDmlExecUtils.insertRow(
        txn
       ,"xxcso_sp_decision_headers"
       ,this
       ,XxcsoSpDecisionHeadersVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_HEADER +
          XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
          XxcsoConstants.TOKEN_VALUE_CREATE
      );
    }

    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード更新処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    replaceNumber();

    try
    {
      XxcsoCustomDmlExecUtils.updateRow(
        txn
       ,"xxcso_sp_decision_headers"
       ,this
       ,XxcsoSpDecisionHeadersVEOImpl.getDefinitionObject()
      );
    }
    catch ( SQLException e )
    {
      XxcsoUtils.unexpected(txn, e);
      throw XxcsoMessage.createSqlErrorMessage(
        e,
        XxcsoConstants.TOKEN_VALUE_SP_DECISION_HEADER+
          XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
          XxcsoConstants.TOKEN_VALUE_UPDATE
      );
    }

    XxcsoUtils.debug(txn, "[END]");    
  }


  /*****************************************************************************
   * レコード削除処理です。
   * 呼ばれないはずなので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");    
  }


  
  /*****************************************************************************
   * 数値データ置き換え処理
   *****************************************************************************
   */
  private void replaceNumber()
  {
    if ( getSeleNumber() != null &&
         ! "".equals(getSeleNumber())
       )
    {
      populateAttribute(
        SELENUMBER
       ,getSeleNumber().replaceAll(",","")
      );
    }
    if ( getContractYearDate() != null &&
         ! "".equals(getContractYearDate())
       )
    {
      populateAttribute(
        CONTRACTYEARDATE
       ,getContractYearDate().replaceAll(",","")
      );
    }
    if ( getInstallSupportAmt() != null &&
         ! "".equals(getInstallSupportAmt())
       )
    {
      populateAttribute(
        INSTALLSUPPORTAMT
       ,getInstallSupportAmt().replaceAll(",","")
      );
    }
    if ( getInstallSupportAmt2() != null &&
         ! "".equals(getInstallSupportAmt2())
       )
    {
      populateAttribute(
        INSTALLSUPPORTAMT2
       ,getInstallSupportAmt2().replaceAll(",","")
      );
    }
    if ( getPaymentCycle() != null &&
         ! "".equals(getPaymentCycle())
       )
    {
      populateAttribute(
        PAYMENTCYCLE
       ,getPaymentCycle().replaceAll(",","")
      );
    }
    if ( getElectricityAmount() != null &&
         ! "".equals(getElectricityAmount())
       )
    {
      populateAttribute(
        ELECTRICITYAMOUNT
       ,getElectricityAmount().replaceAll(",","")
      );
    }
    if ( getSalesMonth() != null &&
         ! "".equals(getSalesMonth())
       )
    {
      populateAttribute(
        SALESMONTH
       ,getSalesMonth().replaceAll(",","")
      );
    }
    if ( getSalesYear() != null &&
         ! "".equals(getSalesYear())
       )
    {
      populateAttribute(
        SALESYEAR
       ,getSalesYear().replaceAll(",","")
      );
    }
    if ( getSalesGrossMarginRate() != null &&
         ! "".equals(getSalesGrossMarginRate())
       )
    {
      populateAttribute(
        SALESGROSSMARGINRATE
       ,getSalesGrossMarginRate().replaceAll(",","")
      );
    }
    if ( getYearGrossMarginAmt() != null &&
         ! "".equals(getYearGrossMarginAmt())
       )
    {
      populateAttribute(
        YEARGROSSMARGINAMT
       ,getYearGrossMarginAmt().replaceAll(",","")
      );
    }
    if ( getBmRate() != null &&
         ! "".equals(getBmRate())
       )
    {
      populateAttribute(
        BMRATE
       ,getBmRate().replaceAll(",","")
      );
    }
    if ( getVdSalesCharge() != null &&
         ! "".equals(getVdSalesCharge())
       )
    {
      populateAttribute(
        VDSALESCHARGE
       ,getVdSalesCharge().replaceAll(",","")
      );
    }
    if ( getInstallSupportAmtYear() != null &&
         ! "".equals(getInstallSupportAmtYear())
       )
    {
      populateAttribute(
        INSTALLSUPPORTAMTYEAR
       ,getInstallSupportAmtYear().replaceAll(",","")
      );
    }
    if ( getLeaseChargeMonth() != null &&
         ! "".equals(getLeaseChargeMonth())
       )
    {
      populateAttribute(
        LEASECHARGEMONTH
       ,getLeaseChargeMonth().replaceAll(",","")
      );
    }
    if ( getConstructionCharge() != null &&
         ! "".equals(getConstructionCharge())
       )
    {
      populateAttribute(
        CONSTRUCTIONCHARGE
       ,getConstructionCharge().replaceAll(",","")
      );
    }
    if ( getVdLeaseCharge() != null &&
         ! "".equals(getVdLeaseCharge())
       )
    {
      populateAttribute(
        VDLEASECHARGE
       ,getVdLeaseCharge().replaceAll(",","")
      );
    }
    if ( getElectricityAmtMonth() != null &&
         ! "".equals(getElectricityAmtMonth())
       )
    {
      populateAttribute(
        ELECTRICITYAMTMONTH
       ,getElectricityAmtMonth().replaceAll(",","")
      );
    }
    if ( getElectricityAmtYear() != null &&
         ! "".equals(getElectricityAmtYear())
       )
    {
      populateAttribute(
        ELECTRICITYAMTYEAR
       ,getElectricityAmtYear().replaceAll(",","")
      );
    }
    if ( getTransportationCharge() != null &&
         ! "".equals(getTransportationCharge())
       )
    {
      populateAttribute(
        TRANSPORTATIONCHARGE
       ,getTransportationCharge().replaceAll(",","")
      );
    }
    if ( getLaborCostOther() != null &&
         ! "".equals(getLaborCostOther())
       )
    {
      populateAttribute(
        LABORCOSTOTHER
       ,getLaborCostOther().replaceAll(",","")
      );
    }
    if ( getTotalCost() != null &&
         ! "".equals(getTotalCost())
       )
    {
      populateAttribute(
        TOTALCOST
       ,getTotalCost().replaceAll(",","")
      );
    }
    if ( getOperatingProfit() != null &&
         ! "".equals(getOperatingProfit())
       )
    {
      populateAttribute(
        OPERATINGPROFIT
       ,getOperatingProfit().replaceAll(",","")
      );
    }
    if ( getOperatingProfitRate() != null &&
         ! "".equals(getOperatingProfitRate())
       )
    {
      populateAttribute(
        OPERATINGPROFITRATE
       ,getOperatingProfitRate().replaceAll(",","")
      );
    }
    if ( getBreakEvenPoint() != null &&
         ! "".equals(getBreakEvenPoint())
       )
    {
      populateAttribute(
        BREAKEVENPOINT
       ,getBreakEvenPoint().replaceAll(",","")
      );
    }
// 2014-12-15 [E_本稼動_12565] Add Start
    if ( getContractYearMonth() != null &&
         ! "".equals(getContractYearMonth())
       )
    {
      populateAttribute(
        CONTRACTYEARMONTH
       ,getContractYearMonth().replaceAll(",","")
      );
    }
    if ( getContractStartYear() != null &&
         ! "".equals(getContractStartYear())
       )
    {
      populateAttribute(
        CONTRACTSTARTYEAR
       ,getContractStartYear().replaceAll(",","")
      );
    }
    if ( getContractStartMonth() != null &&
         ! "".equals(getContractStartMonth())
       )
    {
      populateAttribute(
        CONTRACTSTARTMONTH
       ,getContractStartMonth().replaceAll(",","")
      );
    }
    if ( getContractEndMonth() != null &&
         ! "".equals(getContractEndMonth())
       )
    {
      populateAttribute(
        CONTRACTENDMONTH
       ,getContractEndMonth().replaceAll(",","")
      );
    }
    if ( getContractEndYear() != null &&
         ! "".equals(getContractEndYear())
       )
    {
      populateAttribute(
        CONTRACTENDYEAR
       ,getContractEndYear().replaceAll(",","")
      );
    }
    if ( getAdAssetsAmt() != null &&
         ! "".equals(getAdAssetsAmt())
       )
    {
      populateAttribute(
        ADASSETSAMT
       ,getAdAssetsAmt().replaceAll(",","")
      );
    }
    if ( getAdAssetsThisTime() != null &&
         ! "".equals(getAdAssetsThisTime())
       )
    {
      populateAttribute(
        ADASSETSTHISTIME
       ,getAdAssetsThisTime().replaceAll(",","")
      );
    }
    if ( getAdAssetsPaymentYear() != null &&
         ! "".equals(getAdAssetsPaymentYear())
       )
    {
      populateAttribute(
        ADASSETSPAYMENTYEAR
       ,getAdAssetsPaymentYear().replaceAll(",","")
      );
    }
    if ( getInstallSuppAmt() != null &&
         ! "".equals(getInstallSuppAmt())
       )
    {
      populateAttribute(
        INSTALLSUPPAMT
       ,getInstallSuppAmt().replaceAll(",","")
      );
    }
    if ( getInstallSuppThisTime() != null &&
         ! "".equals(getInstallSuppThisTime())
       )
    {
      populateAttribute(
        INSTALLSUPPTHISTIME
       ,getInstallSuppThisTime().replaceAll(",","")
      );
    }
    if ( getInstallSuppPaymentYear() != null &&
         ! "".equals(getInstallSuppPaymentYear())
       )
    {
      populateAttribute(
        INSTALLSUPPPAYMENTYEAR
       ,getInstallSuppPaymentYear().replaceAll(",","")
      );
    }
    if ( getIntroChgAmt() != null &&
         ! "".equals(getIntroChgAmt())
       )
    {
      populateAttribute(
        INTROCHGAMT
       ,getIntroChgAmt().replaceAll(",","")
      );
    }
    if ( getIntroChgThisTime() != null &&
         ! "".equals(getIntroChgThisTime())
       )
    {
      populateAttribute(
        INTROCHGTHISTIME
       ,getIntroChgThisTime().replaceAll(",","")
      );
    }
    if ( getIntroChgPaymentYear() != null &&
         ! "".equals(getIntroChgPaymentYear())
       )
    {
      populateAttribute(
        INTROCHGPAYMENTYEAR
       ,getIntroChgPaymentYear().replaceAll(",","")
      );
    }
    if ( getIntroChgPerSalesPrice() != null &&
         ! "".equals(getIntroChgPerSalesPrice())
       )
    {
      populateAttribute(
        INTROCHGPERSALESPRICE
       ,getIntroChgPerSalesPrice().replaceAll(",","")
      );
    }
    if ( getIntroChgPerPiece() != null &&
         ! "".equals(getIntroChgPerPiece())
       )
    {
      populateAttribute(
        INTROCHGPERPIECE
       ,getIntroChgPerPiece().replaceAll(",","")
      );
    }
// 2014-12-15 [E_本稼動_12565] Add End
  }


  /**
   * 
   * Gets the attribute value for SpDecisionHeaderId, using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for SpDecisionNumber, using the alias name SpDecisionNumber
   */
  public String getSpDecisionNumber()
  {
    return (String)getAttributeInternal(SPDECISIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionNumber
   */
  public void setSpDecisionNumber(String value)
  {
    setAttributeInternal(SPDECISIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for SpDecisionType, using the alias name SpDecisionType
   */
  public String getSpDecisionType()
  {
    return (String)getAttributeInternal(SPDECISIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionType
   */
  public void setSpDecisionType(String value)
  {
    setAttributeInternal(SPDECISIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for Status, using the alias name Status
   */
  public String getStatus()
  {
    return (String)getAttributeInternal(STATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Status
   */
  public void setStatus(String value)
  {
    setAttributeInternal(STATUS, value);
  }

  /**
   * 
   * Gets the attribute value for ApplicationNumber, using the alias name ApplicationNumber
   */
  public Number getApplicationNumber()
  {
    return (Number)getAttributeInternal(APPLICATIONNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApplicationNumber
   */
  public void setApplicationNumber(Number value)
  {
    setAttributeInternal(APPLICATIONNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ApplicationDate, using the alias name ApplicationDate
   */
  public Date getApplicationDate()
  {
    return (Date)getAttributeInternal(APPLICATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApplicationDate
   */
  public void setApplicationDate(Date value)
  {
    setAttributeInternal(APPLICATIONDATE, value);
  }





  /**
   * 
   * Gets the attribute value for ApprovalCompleteDate, using the alias name ApprovalCompleteDate
   */
  public Date getApprovalCompleteDate()
  {
    return (Date)getAttributeInternal(APPROVALCOMPLETEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApprovalCompleteDate
   */
  public void setApprovalCompleteDate(Date value)
  {
    setAttributeInternal(APPROVALCOMPLETEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ApplicationCode, using the alias name ApplicationCode
   */
  public String getApplicationCode()
  {
    return (String)getAttributeInternal(APPLICATIONCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApplicationCode
   */
  public void setApplicationCode(String value)
  {
    setAttributeInternal(APPLICATIONCODE, value);
  }

  /**
   * 
   * Gets the attribute value for AppBaseCode, using the alias name AppBaseCode
   */
  public String getAppBaseCode()
  {
    return (String)getAttributeInternal(APPBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AppBaseCode
   */
  public void setAppBaseCode(String value)
  {
    setAttributeInternal(APPBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for ApplicationType, using the alias name ApplicationType
   */
  public String getApplicationType()
  {
    return (String)getAttributeInternal(APPLICATIONTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApplicationType
   */
  public void setApplicationType(String value)
  {
    setAttributeInternal(APPLICATIONTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for NewoldType, using the alias name NewoldType
   */
  public String getNewoldType()
  {
    return (String)getAttributeInternal(NEWOLDTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NewoldType
   */
  public void setNewoldType(String value)
  {
    setAttributeInternal(NEWOLDTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for SeleNumber, using the alias name SeleNumber
   */
  public String getSeleNumber()
  {
    return (String)getAttributeInternal(SELENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SeleNumber
   */
  public void setSeleNumber(String value)
  {
    setAttributeInternal(SELENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for MakerCode, using the alias name MakerCode
   */
  public String getMakerCode()
  {
    return (String)getAttributeInternal(MAKERCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for MakerCode
   */
  public void setMakerCode(String value)
  {
    setAttributeInternal(MAKERCODE, value);
  }

  /**
   * 
   * Gets the attribute value for StandardType, using the alias name StandardType
   */
  public String getStandardType()
  {
    return (String)getAttributeInternal(STANDARDTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for StandardType
   */
  public void setStandardType(String value)
  {
    setAttributeInternal(STANDARDTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for UnNumber, using the alias name UnNumber
   */
  public String getUnNumber()
  {
    return (String)getAttributeInternal(UNNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for UnNumber
   */
  public void setUnNumber(String value)
  {
    setAttributeInternal(UNNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for InstallDate, using the alias name InstallDate
   */
  public Date getInstallDate()
  {
    return (Date)getAttributeInternal(INSTALLDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallDate
   */
  public void setInstallDate(Date value)
  {
    setAttributeInternal(INSTALLDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LeaseCompany, using the alias name LeaseCompany
   */
  public String getLeaseCompany()
  {
    return (String)getAttributeInternal(LEASECOMPANY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LeaseCompany
   */
  public void setLeaseCompany(String value)
  {
    setAttributeInternal(LEASECOMPANY, value);
  }

  /**
   * 
   * Gets the attribute value for ConditionBusinessType, using the alias name ConditionBusinessType
   */
  public String getConditionBusinessType()
  {
    return (String)getAttributeInternal(CONDITIONBUSINESSTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ConditionBusinessType
   */
  public void setConditionBusinessType(String value)
  {
    setAttributeInternal(CONDITIONBUSINESSTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for AllContainerType, using the alias name AllContainerType
   */
  public String getAllContainerType()
  {
    return (String)getAttributeInternal(ALLCONTAINERTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AllContainerType
   */
  public void setAllContainerType(String value)
  {
    setAttributeInternal(ALLCONTAINERTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ContractYearDate, using the alias name ContractYearDate
   */
  public String getContractYearDate()
  {
    return (String)getAttributeInternal(CONTRACTYEARDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractYearDate
   */
  public void setContractYearDate(String value)
  {
    setAttributeInternal(CONTRACTYEARDATE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSupportAmt, using the alias name InstallSupportAmt
   */
  public String getInstallSupportAmt()
  {
    return (String)getAttributeInternal(INSTALLSUPPORTAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSupportAmt
   */
  public void setInstallSupportAmt(String value)
  {
    setAttributeInternal(INSTALLSUPPORTAMT, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSupportAmt2, using the alias name InstallSupportAmt2
   */
  public String getInstallSupportAmt2()
  {
    return (String)getAttributeInternal(INSTALLSUPPORTAMT2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSupportAmt2
   */
  public void setInstallSupportAmt2(String value)
  {
    setAttributeInternal(INSTALLSUPPORTAMT2, value);
  }

  /**
   * 
   * Gets the attribute value for PaymentCycle, using the alias name PaymentCycle
   */
  public String getPaymentCycle()
  {
    return (String)getAttributeInternal(PAYMENTCYCLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PaymentCycle
   */
  public void setPaymentCycle(String value)
  {
    setAttributeInternal(PAYMENTCYCLE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricityType, using the alias name ElectricityType
   */
  public String getElectricityType()
  {
    return (String)getAttributeInternal(ELECTRICITYTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricityType
   */
  public void setElectricityType(String value)
  {
    setAttributeInternal(ELECTRICITYTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricityAmount, using the alias name ElectricityAmount
   */
  public String getElectricityAmount()
  {
    return (String)getAttributeInternal(ELECTRICITYAMOUNT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricityAmount
   */
  public void setElectricityAmount(String value)
  {
    setAttributeInternal(ELECTRICITYAMOUNT, value);
  }

  /**
   * 
   * Gets the attribute value for ConditionReason, using the alias name ConditionReason
   */
  public String getConditionReason()
  {
    return (String)getAttributeInternal(CONDITIONREASON);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ConditionReason
   */
  public void setConditionReason(String value)
  {
    setAttributeInternal(CONDITIONREASON, value);
  }

  /**
   * 
   * Gets the attribute value for Bm1SendType, using the alias name Bm1SendType
   */
  public String getBm1SendType()
  {
    return (String)getAttributeInternal(BM1SENDTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Bm1SendType
   */
  public void setBm1SendType(String value)
  {
    setAttributeInternal(BM1SENDTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for OtherContent, using the alias name OtherContent
   */
  public String getOtherContent()
  {
    return (String)getAttributeInternal(OTHERCONTENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for OtherContent
   */
  public void setOtherContent(String value)
  {
    setAttributeInternal(OTHERCONTENT, value);
  }

  /**
   * 
   * Gets the attribute value for SalesMonth, using the alias name SalesMonth
   */
  public String getSalesMonth()
  {
    return (String)getAttributeInternal(SALESMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesMonth
   */
  public void setSalesMonth(String value)
  {
    setAttributeInternal(SALESMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for SalesYear, using the alias name SalesYear
   */
  public String getSalesYear()
  {
    return (String)getAttributeInternal(SALESYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesYear
   */
  public void setSalesYear(String value)
  {
    setAttributeInternal(SALESYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for SalesGrossMarginRate, using the alias name SalesGrossMarginRate
   */
  public String getSalesGrossMarginRate()
  {
    return (String)getAttributeInternal(SALESGROSSMARGINRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesGrossMarginRate
   */
  public void setSalesGrossMarginRate(String value)
  {
    setAttributeInternal(SALESGROSSMARGINRATE, value);
  }

  /**
   * 
   * Gets the attribute value for YearGrossMarginAmt, using the alias name YearGrossMarginAmt
   */
  public String getYearGrossMarginAmt()
  {
    return (String)getAttributeInternal(YEARGROSSMARGINAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for YearGrossMarginAmt
   */
  public void setYearGrossMarginAmt(String value)
  {
    setAttributeInternal(YEARGROSSMARGINAMT, value);
  }

  /**
   * 
   * Gets the attribute value for BmRate, using the alias name BmRate
   */
  public String getBmRate()
  {
    return (String)getAttributeInternal(BMRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BmRate
   */
  public void setBmRate(String value)
  {
    setAttributeInternal(BMRATE, value);
  }

  /**
   * 
   * Gets the attribute value for VdSalesCharge, using the alias name VdSalesCharge
   */
  public String getVdSalesCharge()
  {
    return (String)getAttributeInternal(VDSALESCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for VdSalesCharge
   */
  public void setVdSalesCharge(String value)
  {
    setAttributeInternal(VDSALESCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSupportAmtYear, using the alias name InstallSupportAmtYear
   */
  public String getInstallSupportAmtYear()
  {
    return (String)getAttributeInternal(INSTALLSUPPORTAMTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSupportAmtYear
   */
  public void setInstallSupportAmtYear(String value)
  {
    setAttributeInternal(INSTALLSUPPORTAMTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for LeaseChargeMonth, using the alias name LeaseChargeMonth
   */
  public String getLeaseChargeMonth()
  {
    return (String)getAttributeInternal(LEASECHARGEMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LeaseChargeMonth
   */
  public void setLeaseChargeMonth(String value)
  {
    setAttributeInternal(LEASECHARGEMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for ConstructionCharge, using the alias name ConstructionCharge
   */
  public String getConstructionCharge()
  {
    return (String)getAttributeInternal(CONSTRUCTIONCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ConstructionCharge
   */
  public void setConstructionCharge(String value)
  {
    setAttributeInternal(CONSTRUCTIONCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for VdLeaseCharge, using the alias name VdLeaseCharge
   */
  public String getVdLeaseCharge()
  {
    return (String)getAttributeInternal(VDLEASECHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for VdLeaseCharge
   */
  public void setVdLeaseCharge(String value)
  {
    setAttributeInternal(VDLEASECHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricityAmtMonth, using the alias name ElectricityAmtMonth
   */
  public String getElectricityAmtMonth()
  {
    return (String)getAttributeInternal(ELECTRICITYAMTMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricityAmtMonth
   */
  public void setElectricityAmtMonth(String value)
  {
    setAttributeInternal(ELECTRICITYAMTMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricityAmtYear, using the alias name ElectricityAmtYear
   */
  public String getElectricityAmtYear()
  {
    return (String)getAttributeInternal(ELECTRICITYAMTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricityAmtYear
   */
  public void setElectricityAmtYear(String value)
  {
    setAttributeInternal(ELECTRICITYAMTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for TransportationCharge, using the alias name TransportationCharge
   */
  public String getTransportationCharge()
  {
    return (String)getAttributeInternal(TRANSPORTATIONCHARGE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TransportationCharge
   */
  public void setTransportationCharge(String value)
  {
    setAttributeInternal(TRANSPORTATIONCHARGE, value);
  }

  /**
   * 
   * Gets the attribute value for LaborCostOther, using the alias name LaborCostOther
   */
  public String getLaborCostOther()
  {
    return (String)getAttributeInternal(LABORCOSTOTHER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LaborCostOther
   */
  public void setLaborCostOther(String value)
  {
    setAttributeInternal(LABORCOSTOTHER, value);
  }

  /**
   * 
   * Gets the attribute value for TotalCost, using the alias name TotalCost
   */
  public String getTotalCost()
  {
    return (String)getAttributeInternal(TOTALCOST);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TotalCost
   */
  public void setTotalCost(String value)
  {
    setAttributeInternal(TOTALCOST, value);
  }

  /**
   * 
   * Gets the attribute value for OperatingProfit, using the alias name OperatingProfit
   */
  public String getOperatingProfit()
  {
    return (String)getAttributeInternal(OPERATINGPROFIT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for OperatingProfit
   */
  public void setOperatingProfit(String value)
  {
    setAttributeInternal(OPERATINGPROFIT, value);
  }

  /**
   * 
   * Gets the attribute value for OperatingProfitRate, using the alias name OperatingProfitRate
   */
  public String getOperatingProfitRate()
  {
    return (String)getAttributeInternal(OPERATINGPROFITRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for OperatingProfitRate
   */
  public void setOperatingProfitRate(String value)
  {
    setAttributeInternal(OPERATINGPROFITRATE, value);
  }

  /**
   * 
   * Gets the attribute value for BreakEvenPoint, using the alias name BreakEvenPoint
   */
  public String getBreakEvenPoint()
  {
    return (String)getAttributeInternal(BREAKEVENPOINT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BreakEvenPoint
   */
  public void setBreakEvenPoint(String value)
  {
    setAttributeInternal(BREAKEVENPOINT, value);
  }

  /**
   * 
   * Gets the attribute value for CreatedBy, using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CreationDate, using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdatedBy, using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateDate, using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LastUpdateLogin, using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for RequestId, using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramApplicationId, using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramId, using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for ProgramUpdateDate, using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ProgramUpdateDate
   */
  public void setProgramUpdateDate(Date value)
  {
    setAttributeInternal(PROGRAMUPDATEDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case SPDECISIONNUMBER:
        return getSpDecisionNumber();
      case SPDECISIONTYPE:
        return getSpDecisionType();
      case STATUS:
        return getStatus();
      case APPLICATIONNUMBER:
        return getApplicationNumber();
      case APPLICATIONDATE:
        return getApplicationDate();
      case APPROVALCOMPLETEDATE:
        return getApprovalCompleteDate();
      case APPLICATIONCODE:
        return getApplicationCode();
      case APPBASECODE:
        return getAppBaseCode();
      case APPLICATIONTYPE:
        return getApplicationType();
      case NEWOLDTYPE:
        return getNewoldType();
      case SELENUMBER:
        return getSeleNumber();
      case MAKERCODE:
        return getMakerCode();
      case STANDARDTYPE:
        return getStandardType();
      case UNNUMBER:
        return getUnNumber();
      case INSTALLDATE:
        return getInstallDate();
      case LEASECOMPANY:
        return getLeaseCompany();
      case CONDITIONBUSINESSTYPE:
        return getConditionBusinessType();
      case ALLCONTAINERTYPE:
        return getAllContainerType();
      case CONTRACTYEARDATE:
        return getContractYearDate();
      case INSTALLSUPPORTAMT:
        return getInstallSupportAmt();
      case INSTALLSUPPORTAMT2:
        return getInstallSupportAmt2();
      case PAYMENTCYCLE:
        return getPaymentCycle();
      case ELECTRICITYTYPE:
        return getElectricityType();
      case ELECTRICITYAMOUNT:
        return getElectricityAmount();
      case CONDITIONREASON:
        return getConditionReason();
      case BM1SENDTYPE:
        return getBm1SendType();
      case OTHERCONTENT:
        return getOtherContent();
      case SALESMONTH:
        return getSalesMonth();
      case SALESYEAR:
        return getSalesYear();
      case SALESGROSSMARGINRATE:
        return getSalesGrossMarginRate();
      case YEARGROSSMARGINAMT:
        return getYearGrossMarginAmt();
      case BMRATE:
        return getBmRate();
      case VDSALESCHARGE:
        return getVdSalesCharge();
      case INSTALLSUPPORTAMTYEAR:
        return getInstallSupportAmtYear();
      case LEASECHARGEMONTH:
        return getLeaseChargeMonth();
      case CONSTRUCTIONCHARGE:
        return getConstructionCharge();
      case VDLEASECHARGE:
        return getVdLeaseCharge();
      case ELECTRICITYAMTMONTH:
        return getElectricityAmtMonth();
      case ELECTRICITYAMTYEAR:
        return getElectricityAmtYear();
      case TRANSPORTATIONCHARGE:
        return getTransportationCharge();
      case LABORCOSTOTHER:
        return getLaborCostOther();
      case TOTALCOST:
        return getTotalCost();
      case OPERATINGPROFIT:
        return getOperatingProfit();
      case OPERATINGPROFITRATE:
        return getOperatingProfitRate();
      case BREAKEVENPOINT:
        return getBreakEvenPoint();
      case CREATEDBY:
        return getCreatedBy();
      case CREATIONDATE:
        return getCreationDate();
      case LASTUPDATEDBY:
        return getLastUpdatedBy();
      case LASTUPDATEDATE:
        return getLastUpdateDate();
      case LASTUPDATELOGIN:
        return getLastUpdateLogin();
      case REQUESTID:
        return getRequestId();
      case PROGRAMAPPLICATIONID:
        return getProgramApplicationId();
      case PROGRAMID:
        return getProgramId();
      case PROGRAMUPDATEDATE:
        return getProgramUpdateDate();
      case CONTRACTYEARMONTH:
        return getContractYearMonth();
      case CONTRACTSTARTYEAR:
        return getContractStartYear();
      case CONTRACTSTARTMONTH:
        return getContractStartMonth();
      case CONTRACTENDYEAR:
        return getContractEndYear();
      case CONTRACTENDMONTH:
        return getContractEndMonth();
      case BIDDINGITEM:
        return getBiddingItem();
      case CANCELLBEFOREMATURITY:
        return getCancellBeforeMaturity();
      case ADASSETSTYPE:
        return getAdAssetsType();
      case ADASSETSAMT:
        return getAdAssetsAmt();
      case ADASSETSTHISTIME:
        return getAdAssetsThisTime();
      case ADASSETSPAYMENTYEAR:
        return getAdAssetsPaymentYear();
      case ADASSETSPAYMENTDATE:
        return getAdAssetsPaymentDate();
      case TAXTYPE:
        return getTaxType();
      case INSTALLSUPPTYPE:
        return getInstallSuppType();
      case INSTALLSUPPPAYMENTTYPE:
        return getInstallSuppPaymentType();
      case INSTALLSUPPAMT:
        return getInstallSuppAmt();
      case INSTALLSUPPTHISTIME:
        return getInstallSuppThisTime();
      case INSTALLSUPPPAYMENTYEAR:
        return getInstallSuppPaymentYear();
      case INSTALLSUPPPAYMENTDATE:
        return getInstallSuppPaymentDate();
      case ELECTRICPAYMENTTYPE:
        return getElectricPaymentType();
      case ELECTRICPAYMENTCHANGETYPE:
        return getElectricPaymentChangeType();
      case ELECTRICPAYMENTCYCLE:
        return getElectricPaymentCycle();
      case ELECTRICCLOSINGDATE:
        return getElectricClosingDate();
      case ELECTRICTRANSMONTH:
        return getElectricTransMonth();
      case ELECTRICTRANSDATE:
        return getElectricTransDate();
      case ELECTRICTRANSNAME:
        return getElectricTransName();
      case ELECTRICTRANSNAMEALT:
        return getElectricTransNameAlt();
      case INTROCHGTYPE:
        return getIntroChgType();
      case INTROCHGPAYMENTTYPE:
        return getIntroChgPaymentType();
      case INTROCHGAMT:
        return getIntroChgAmt();
      case INTROCHGTHISTIME:
        return getIntroChgThisTime();
      case INTROCHGPAYMENTYEAR:
        return getIntroChgPaymentYear();
      case INTROCHGPAYMENTDATE:
        return getIntroChgPaymentDate();
      case INTROCHGPERSALESPRICE:
        return getIntroChgPerSalesPrice();
      case INTROCHGPERPIECE:
        return getIntroChgPerPiece();
      case INTROCHGCLOSINGDATE:
        return getIntroChgClosingDate();
      case INTROCHGTRANSMONTH:
        return getIntroChgTransMonth();
      case INTROCHGTRANSDATE:
        return getIntroChgTransDate();
      case INTROCHGTRANSNAME:
        return getIntroChgTransName();
      case INTROCHGTRANSNAMEALT:
        return getIntroChgTransNameAlt();
      case XXCSOSPDECISIONATTACHESEO:
        return getXxcsoSpDecisionAttachesEO();
      case XXCSOSPDECISIONCUSTSVEO:
        return getXxcsoSpDecisionCustsVEO();
      case XXCSOSPDECISIONLINESVEO:
        return getXxcsoSpDecisionLinesVEO();
      case XXCSOSPDECISIONSENDSEO:
        return getXxcsoSpDecisionSendsEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case SPDECISIONNUMBER:
        setSpDecisionNumber((String)value);
        return;
      case SPDECISIONTYPE:
        setSpDecisionType((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case APPLICATIONNUMBER:
        setApplicationNumber((Number)value);
        return;
      case APPLICATIONDATE:
        setApplicationDate((Date)value);
        return;
      case APPROVALCOMPLETEDATE:
        setApprovalCompleteDate((Date)value);
        return;
      case APPLICATIONCODE:
        setApplicationCode((String)value);
        return;
      case APPBASECODE:
        setAppBaseCode((String)value);
        return;
      case APPLICATIONTYPE:
        setApplicationType((String)value);
        return;
      case NEWOLDTYPE:
        setNewoldType((String)value);
        return;
      case SELENUMBER:
        setSeleNumber((String)value);
        return;
      case MAKERCODE:
        setMakerCode((String)value);
        return;
      case STANDARDTYPE:
        setStandardType((String)value);
        return;
      case UNNUMBER:
        setUnNumber((String)value);
        return;
      case INSTALLDATE:
        setInstallDate((Date)value);
        return;
      case LEASECOMPANY:
        setLeaseCompany((String)value);
        return;
      case CONDITIONBUSINESSTYPE:
        setConditionBusinessType((String)value);
        return;
      case ALLCONTAINERTYPE:
        setAllContainerType((String)value);
        return;
      case CONTRACTYEARDATE:
        setContractYearDate((String)value);
        return;
      case INSTALLSUPPORTAMT:
        setInstallSupportAmt((String)value);
        return;
      case INSTALLSUPPORTAMT2:
        setInstallSupportAmt2((String)value);
        return;
      case PAYMENTCYCLE:
        setPaymentCycle((String)value);
        return;
      case ELECTRICITYTYPE:
        setElectricityType((String)value);
        return;
      case ELECTRICITYAMOUNT:
        setElectricityAmount((String)value);
        return;
      case CONDITIONREASON:
        setConditionReason((String)value);
        return;
      case BM1SENDTYPE:
        setBm1SendType((String)value);
        return;
      case OTHERCONTENT:
        setOtherContent((String)value);
        return;
      case SALESMONTH:
        setSalesMonth((String)value);
        return;
      case SALESYEAR:
        setSalesYear((String)value);
        return;
      case SALESGROSSMARGINRATE:
        setSalesGrossMarginRate((String)value);
        return;
      case YEARGROSSMARGINAMT:
        setYearGrossMarginAmt((String)value);
        return;
      case BMRATE:
        setBmRate((String)value);
        return;
      case VDSALESCHARGE:
        setVdSalesCharge((String)value);
        return;
      case INSTALLSUPPORTAMTYEAR:
        setInstallSupportAmtYear((String)value);
        return;
      case LEASECHARGEMONTH:
        setLeaseChargeMonth((String)value);
        return;
      case CONSTRUCTIONCHARGE:
        setConstructionCharge((String)value);
        return;
      case VDLEASECHARGE:
        setVdLeaseCharge((String)value);
        return;
      case ELECTRICITYAMTMONTH:
        setElectricityAmtMonth((String)value);
        return;
      case ELECTRICITYAMTYEAR:
        setElectricityAmtYear((String)value);
        return;
      case TRANSPORTATIONCHARGE:
        setTransportationCharge((String)value);
        return;
      case LABORCOSTOTHER:
        setLaborCostOther((String)value);
        return;
      case TOTALCOST:
        setTotalCost((String)value);
        return;
      case OPERATINGPROFIT:
        setOperatingProfit((String)value);
        return;
      case OPERATINGPROFITRATE:
        setOperatingProfitRate((String)value);
        return;
      case BREAKEVENPOINT:
        setBreakEvenPoint((String)value);
        return;
      case CREATEDBY:
        setCreatedBy((Number)value);
        return;
      case CREATIONDATE:
        setCreationDate((Date)value);
        return;
      case LASTUPDATEDBY:
        setLastUpdatedBy((Number)value);
        return;
      case LASTUPDATEDATE:
        setLastUpdateDate((Date)value);
        return;
      case LASTUPDATELOGIN:
        setLastUpdateLogin((Number)value);
        return;
      case REQUESTID:
        setRequestId((Number)value);
        return;
      case PROGRAMAPPLICATIONID:
        setProgramApplicationId((Number)value);
        return;
      case PROGRAMID:
        setProgramId((Number)value);
        return;
      case PROGRAMUPDATEDATE:
        setProgramUpdateDate((Date)value);
        return;
      case CONTRACTYEARMONTH:
        setContractYearMonth((String)value);
        return;
      case CONTRACTSTARTYEAR:
        setContractStartYear((String)value);
        return;
      case CONTRACTSTARTMONTH:
        setContractStartMonth((String)value);
        return;
      case CONTRACTENDYEAR:
        setContractEndYear((String)value);
        return;
      case CONTRACTENDMONTH:
        setContractEndMonth((String)value);
        return;
      case BIDDINGITEM:
        setBiddingItem((String)value);
        return;
      case CANCELLBEFOREMATURITY:
        setCancellBeforeMaturity((String)value);
        return;
      case ADASSETSTYPE:
        setAdAssetsType((String)value);
        return;
      case ADASSETSAMT:
        setAdAssetsAmt((String)value);
        return;
      case ADASSETSTHISTIME:
        setAdAssetsThisTime((String)value);
        return;
      case ADASSETSPAYMENTYEAR:
        setAdAssetsPaymentYear((String)value);
        return;
      case ADASSETSPAYMENTDATE:
        setAdAssetsPaymentDate((Date)value);
        return;
      case TAXTYPE:
        setTaxType((String)value);
        return;
      case INSTALLSUPPTYPE:
        setInstallSuppType((String)value);
        return;
      case INSTALLSUPPPAYMENTTYPE:
        setInstallSuppPaymentType((String)value);
        return;
      case INSTALLSUPPAMT:
        setInstallSuppAmt((String)value);
        return;
      case INSTALLSUPPTHISTIME:
        setInstallSuppThisTime((String)value);
        return;
      case INSTALLSUPPPAYMENTYEAR:
        setInstallSuppPaymentYear((String)value);
        return;
      case INSTALLSUPPPAYMENTDATE:
        setInstallSuppPaymentDate((Date)value);
        return;
      case ELECTRICPAYMENTTYPE:
        setElectricPaymentType((String)value);
        return;
      case ELECTRICPAYMENTCHANGETYPE:
        setElectricPaymentChangeType((String)value);
        return;
      case ELECTRICPAYMENTCYCLE:
        setElectricPaymentCycle((String)value);
        return;
      case ELECTRICCLOSINGDATE:
        setElectricClosingDate((String)value);
        return;
      case ELECTRICTRANSMONTH:
        setElectricTransMonth((String)value);
        return;
      case ELECTRICTRANSDATE:
        setElectricTransDate((String)value);
        return;
      case ELECTRICTRANSNAME:
        setElectricTransName((String)value);
        return;
      case ELECTRICTRANSNAMEALT:
        setElectricTransNameAlt((String)value);
        return;
      case INTROCHGTYPE:
        setIntroChgType((String)value);
        return;
      case INTROCHGPAYMENTTYPE:
        setIntroChgPaymentType((String)value);
        return;
      case INTROCHGAMT:
        setIntroChgAmt((String)value);
        return;
      case INTROCHGTHISTIME:
        setIntroChgThisTime((String)value);
        return;
      case INTROCHGPAYMENTYEAR:
        setIntroChgPaymentYear((String)value);
        return;
      case INTROCHGPAYMENTDATE:
        setIntroChgPaymentDate((Date)value);
        return;
      case INTROCHGPERSALESPRICE:
        setIntroChgPerSalesPrice((String)value);
        return;
      case INTROCHGPERPIECE:
        setIntroChgPerPiece((String)value);
        return;
      case INTROCHGCLOSINGDATE:
        setIntroChgClosingDate((String)value);
        return;
      case INTROCHGTRANSMONTH:
        setIntroChgTransMonth((String)value);
        return;
      case INTROCHGTRANSDATE:
        setIntroChgTransDate((String)value);
        return;
      case INTROCHGTRANSNAME:
        setIntroChgTransName((String)value);
        return;
      case INTROCHGTRANSNAMEALT:
        setIntroChgTransNameAlt((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }


  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoSpDecisionLinesVEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOSPDECISIONLINESVEO);
  }


  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoSpDecisionCustsVEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOSPDECISIONCUSTSVEO);
  }


  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoSpDecisionSendsEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOSPDECISIONSENDSEO);
  }


  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoSpDecisionAttachesEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOSPDECISIONATTACHESEO);
  }


  /**
   * 
   * Gets the attribute value for ContractYearMonth, using the alias name ContractYearMonth
   */
  public String getContractYearMonth()
  {
    return (String)getAttributeInternal(CONTRACTYEARMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractYearMonth
   */
  public void setContractYearMonth(String value)
  {
    setAttributeInternal(CONTRACTYEARMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for ContractStartYear, using the alias name ContractStartYear
   */
  public String getContractStartYear()
  {
    return (String)getAttributeInternal(CONTRACTSTARTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractStartYear
   */
  public void setContractStartYear(String value)
  {
    setAttributeInternal(CONTRACTSTARTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for ContractStartMonth, using the alias name ContractStartMonth
   */
  public String getContractStartMonth()
  {
    return (String)getAttributeInternal(CONTRACTSTARTMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractStartMonth
   */
  public void setContractStartMonth(String value)
  {
    setAttributeInternal(CONTRACTSTARTMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for ContractEndYear, using the alias name ContractEndYear
   */
  public String getContractEndYear()
  {
    return (String)getAttributeInternal(CONTRACTENDYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractEndYear
   */
  public void setContractEndYear(String value)
  {
    setAttributeInternal(CONTRACTENDYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for ContractEndMonth, using the alias name ContractEndMonth
   */
  public String getContractEndMonth()
  {
    return (String)getAttributeInternal(CONTRACTENDMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractEndMonth
   */
  public void setContractEndMonth(String value)
  {
    setAttributeInternal(CONTRACTENDMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for BiddingItem, using the alias name BiddingItem
   */
  public String getBiddingItem()
  {
    return (String)getAttributeInternal(BIDDINGITEM);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BiddingItem
   */
  public void setBiddingItem(String value)
  {
    setAttributeInternal(BIDDINGITEM, value);
  }

  /**
   * 
   * Gets the attribute value for CancellBeforeMaturity, using the alias name CancellBeforeMaturity
   */
  public String getCancellBeforeMaturity()
  {
    return (String)getAttributeInternal(CANCELLBEFOREMATURITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CancellBeforeMaturity
   */
  public void setCancellBeforeMaturity(String value)
  {
    setAttributeInternal(CANCELLBEFOREMATURITY, value);
  }

  /**
   * 
   * Gets the attribute value for AdAssetsAmt, using the alias name AdAssetsAmt
   */
  public String getAdAssetsAmt()
  {
    return (String)getAttributeInternal(ADASSETSAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AdAssetsAmt
   */
  public void setAdAssetsAmt(String value)
  {
    setAttributeInternal(ADASSETSAMT, value);
  }

  /**
   * 
   * Gets the attribute value for AdAssetsThisTime, using the alias name AdAssetsThisTime
   */
  public String getAdAssetsThisTime()
  {
    return (String)getAttributeInternal(ADASSETSTHISTIME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AdAssetsThisTime
   */
  public void setAdAssetsThisTime(String value)
  {
    setAttributeInternal(ADASSETSTHISTIME, value);
  }



  /**
   * 
   * Gets the attribute value for AdAssetsPaymentDate, using the alias name AdAssetsPaymentDate
   */
  public Date getAdAssetsPaymentDate()
  {
    return (Date)getAttributeInternal(ADASSETSPAYMENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AdAssetsPaymentDate
   */
  public void setAdAssetsPaymentDate(Date value)
  {
    setAttributeInternal(ADASSETSPAYMENTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TaxType, using the alias name TaxType
   */
  public String getTaxType()
  {
    return (String)getAttributeInternal(TAXTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TaxType
   */
  public void setTaxType(String value)
  {
    setAttributeInternal(TAXTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppType, using the alias name InstallSuppType
   */
  public String getInstallSuppType()
  {
    return (String)getAttributeInternal(INSTALLSUPPTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppType
   */
  public void setInstallSuppType(String value)
  {
    setAttributeInternal(INSTALLSUPPTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppPaymentType, using the alias name InstallSuppPaymentType
   */
  public String getInstallSuppPaymentType()
  {
    return (String)getAttributeInternal(INSTALLSUPPPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppPaymentType
   */
  public void setInstallSuppPaymentType(String value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppAmt, using the alias name InstallSuppAmt
   */
  public String getInstallSuppAmt()
  {
    return (String)getAttributeInternal(INSTALLSUPPAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppAmt
   */
  public void setInstallSuppAmt(String value)
  {
    setAttributeInternal(INSTALLSUPPAMT, value);
  }

  /**
   * 
   * Gets the attribute value for InstallSuppThisTime, using the alias name InstallSuppThisTime
   */
  public String getInstallSuppThisTime()
  {
    return (String)getAttributeInternal(INSTALLSUPPTHISTIME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppThisTime
   */
  public void setInstallSuppThisTime(String value)
  {
    setAttributeInternal(INSTALLSUPPTHISTIME, value);
  }



  /**
   * 
   * Gets the attribute value for InstallSuppPaymentDate, using the alias name InstallSuppPaymentDate
   */
  public Date getInstallSuppPaymentDate()
  {
    return (Date)getAttributeInternal(INSTALLSUPPPAYMENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppPaymentDate
   */
  public void setInstallSuppPaymentDate(Date value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricPaymentType, using the alias name ElectricPaymentType
   */
  public String getElectricPaymentType()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricPaymentType
   */
  public void setElectricPaymentType(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricPaymentCycle, using the alias name ElectricPaymentCycle
   */
  public String getElectricPaymentCycle()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCYCLE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricPaymentCycle
   */
  public void setElectricPaymentCycle(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCYCLE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricClosingDate, using the alias name ElectricClosingDate
   */
  public String getElectricClosingDate()
  {
    return (String)getAttributeInternal(ELECTRICCLOSINGDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricClosingDate
   */
  public void setElectricClosingDate(String value)
  {
    setAttributeInternal(ELECTRICCLOSINGDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricTransMonth, using the alias name ElectricTransMonth
   */
  public String getElectricTransMonth()
  {
    return (String)getAttributeInternal(ELECTRICTRANSMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricTransMonth
   */
  public void setElectricTransMonth(String value)
  {
    setAttributeInternal(ELECTRICTRANSMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricTransDate, using the alias name ElectricTransDate
   */
  public String getElectricTransDate()
  {
    return (String)getAttributeInternal(ELECTRICTRANSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricTransDate
   */
  public void setElectricTransDate(String value)
  {
    setAttributeInternal(ELECTRICTRANSDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricTransName, using the alias name ElectricTransName
   */
  public String getElectricTransName()
  {
    return (String)getAttributeInternal(ELECTRICTRANSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricTransName
   */
  public void setElectricTransName(String value)
  {
    setAttributeInternal(ELECTRICTRANSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for ElectricTransNameAlt, using the alias name ElectricTransNameAlt
   */
  public String getElectricTransNameAlt()
  {
    return (String)getAttributeInternal(ELECTRICTRANSNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricTransNameAlt
   */
  public void setElectricTransNameAlt(String value)
  {
    setAttributeInternal(ELECTRICTRANSNAMEALT, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgType, using the alias name IntroChgType
   */
  public String getIntroChgType()
  {
    return (String)getAttributeInternal(INTROCHGTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgType
   */
  public void setIntroChgType(String value)
  {
    setAttributeInternal(INTROCHGTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgPaymentType, using the alias name IntroChgPaymentType
   */
  public String getIntroChgPaymentType()
  {
    return (String)getAttributeInternal(INTROCHGPAYMENTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgPaymentType
   */
  public void setIntroChgPaymentType(String value)
  {
    setAttributeInternal(INTROCHGPAYMENTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgAmt, using the alias name IntroChgAmt
   */
  public String getIntroChgAmt()
  {
    return (String)getAttributeInternal(INTROCHGAMT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgAmt
   */
  public void setIntroChgAmt(String value)
  {
    setAttributeInternal(INTROCHGAMT, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgThisTime, using the alias name IntroChgThisTime
   */
  public String getIntroChgThisTime()
  {
    return (String)getAttributeInternal(INTROCHGTHISTIME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgThisTime
   */
  public void setIntroChgThisTime(String value)
  {
    setAttributeInternal(INTROCHGTHISTIME, value);
  }



  /**
   * 
   * Gets the attribute value for IntroChgPaymentDate, using the alias name IntroChgPaymentDate
   */
  public Date getIntroChgPaymentDate()
  {
    return (Date)getAttributeInternal(INTROCHGPAYMENTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgPaymentDate
   */
  public void setIntroChgPaymentDate(Date value)
  {
    setAttributeInternal(INTROCHGPAYMENTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgPerSalesPrice, using the alias name IntroChgPerSalesPrice
   */
  public String getIntroChgPerSalesPrice()
  {
    return (String)getAttributeInternal(INTROCHGPERSALESPRICE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgPerSalesPrice
   */
  public void setIntroChgPerSalesPrice(String value)
  {
    setAttributeInternal(INTROCHGPERSALESPRICE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgPerPiece, using the alias name IntroChgPerPiece
   */
  public String getIntroChgPerPiece()
  {
    return (String)getAttributeInternal(INTROCHGPERPIECE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgPerPiece
   */
  public void setIntroChgPerPiece(String value)
  {
    setAttributeInternal(INTROCHGPERPIECE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgClosingDate, using the alias name IntroChgClosingDate
   */
  public String getIntroChgClosingDate()
  {
    return (String)getAttributeInternal(INTROCHGCLOSINGDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgClosingDate
   */
  public void setIntroChgClosingDate(String value)
  {
    setAttributeInternal(INTROCHGCLOSINGDATE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgTransMonth, using the alias name IntroChgTransMonth
   */
  public String getIntroChgTransMonth()
  {
    return (String)getAttributeInternal(INTROCHGTRANSMONTH);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgTransMonth
   */
  public void setIntroChgTransMonth(String value)
  {
    setAttributeInternal(INTROCHGTRANSMONTH, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgTransDate, using the alias name IntroChgTransDate
   */
  public String getIntroChgTransDate()
  {
    return (String)getAttributeInternal(INTROCHGTRANSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgTransDate
   */
  public void setIntroChgTransDate(String value)
  {
    setAttributeInternal(INTROCHGTRANSDATE, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgTransName, using the alias name IntroChgTransName
   */
  public String getIntroChgTransName()
  {
    return (String)getAttributeInternal(INTROCHGTRANSNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgTransName
   */
  public void setIntroChgTransName(String value)
  {
    setAttributeInternal(INTROCHGTRANSNAME, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgTransNameAlt, using the alias name IntroChgTransNameAlt
   */
  public String getIntroChgTransNameAlt()
  {
    return (String)getAttributeInternal(INTROCHGTRANSNAMEALT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgTransNameAlt
   */
  public void setIntroChgTransNameAlt(String value)
  {
    setAttributeInternal(INTROCHGTRANSNAMEALT, value);
  }


  /**
   * 
   * Gets the attribute value for AdAssetsType, using the alias name AdAssetsType
   */
  public String getAdAssetsType()
  {
    return (String)getAttributeInternal(ADASSETSTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AdAssetsType
   */
  public void setAdAssetsType(String value)
  {
    setAttributeInternal(ADASSETSTYPE, value);
  }


  /**
   * 
   * Gets the attribute value for InstallSuppPaymentYear, using the alias name InstallSuppPaymentYear
   */
  public String getInstallSuppPaymentYear()
  {
    return (String)getAttributeInternal(INSTALLSUPPPAYMENTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallSuppPaymentYear
   */
  public void setInstallSuppPaymentYear(String value)
  {
    setAttributeInternal(INSTALLSUPPPAYMENTYEAR, value);
  }

  /**
   * 
   * Gets the attribute value for IntroChgPaymentYear, using the alias name IntroChgPaymentYear
   */
  public String getIntroChgPaymentYear()
  {
    return (String)getAttributeInternal(INTROCHGPAYMENTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for IntroChgPaymentYear
   */
  public void setIntroChgPaymentYear(String value)
  {
    setAttributeInternal(INTROCHGPAYMENTYEAR, value);
  }


  /**
   * 
   * Gets the attribute value for AdAssetsPaymentYear, using the alias name AdAssetsPaymentYear
   */
  public String getAdAssetsPaymentYear()
  {
    return (String)getAttributeInternal(ADASSETSPAYMENTYEAR);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for AdAssetsPaymentYear
   */
  public void setAdAssetsPaymentYear(String value)
  {
    setAttributeInternal(ADASSETSPAYMENTYEAR, value);
  }


  /**
   * 
   * Gets the attribute value for ElectricPaymentChangeType, using the alias name ElectricPaymentChangeType
   */
  public String getElectricPaymentChangeType()
  {
    return (String)getAttributeInternal(ELECTRICPAYMENTCHANGETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ElectricPaymentChangeType
   */
  public void setElectricPaymentChangeType(String value)
  {
    setAttributeInternal(ELECTRICPAYMENTCHANGETYPE, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number spDecisionHeaderId)
  {
    return new Key(new Object[] {spDecisionHeaderId});
  }





































































}