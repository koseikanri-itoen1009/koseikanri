/*============================================================================
* ファイル名 : XxcsoContractManagementsEOImpl
* 概要説明   : 契約管理テーブルエンティティクラス
* バージョン : 1.3
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-22 1.0  SCS小川浩  新規作成
* 2010-02-09 1.1  SCS阿部大輔  [E_本稼動_01538]契約書の複数確定対応
* 2015-02-02 1.2  SCSK山下翔太 [E_本稼動_12565]SP専決・契約書画面改修
* 2016-01-06 1.3  SCSK桐生和幸 [E_本稼動_13456]自販機管理システム代替対応
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.RowIterator;
import oracle.jbo.AttributeList;
import oracle.jbo.AlreadyLockedException;
import oracle.jbo.RowNotFoundException;
import oracle.jbo.RowInconsistentException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
// 2010-02-09 [E_本稼動_01538] Mod Start
import oracle.jbo.server.TransactionEvent;
import oracle.jdbc.OracleTypes;
import java.sql.CallableStatement;
import java.sql.SQLException;
// 2010-02-09 [E_本稼動_01538] Mod End

/*******************************************************************************
 * 契約管理テーブルのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoContractManagementsEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int CONTRACTMANAGEMENTID = 0;
  protected static final int CONTRACTNUMBER = 1;
  protected static final int CONTRACTFORMAT = 2;
  protected static final int STATUS = 3;
  protected static final int EMPLOYEENUMBER = 4;
  protected static final int SPDECISIONHEADERID = 5;
  protected static final int CONTRACTEFFECTDATE = 6;
  protected static final int TRANSFERMONTHCODE = 7;
  protected static final int TRANSFERDAYCODE = 8;
  protected static final int CLOSEDAYCODE = 9;
  protected static final int CONTRACTPERIOD = 10;
  protected static final int CANCELLATIONOFFERCODE = 11;
  protected static final int CONTRACTCUSTOMERID = 12;
  protected static final int INSTALLACCOUNTID = 13;
  protected static final int INSTALLACCOUNTNUMBER = 14;
  protected static final int INSTALLPARTYNAME = 15;
  protected static final int INSTALLPOSTALCODE = 16;
  protected static final int INSTALLSTATE = 17;
  protected static final int INSTALLCITY = 18;
  protected static final int INSTALLADDRESS1 = 19;
  protected static final int INSTALLADDRESS2 = 20;
  protected static final int INSTALLDATE = 21;
  protected static final int INSTALLLOCATION = 22;
  protected static final int PUBLISHDEPTCODE = 23;
  protected static final int INSTALLCODE = 24;
  protected static final int COOPERATEFLAG = 25;
  protected static final int BATCHPROCSTATUS = 26;
  protected static final int CREATEDBY = 27;
  protected static final int CREATIONDATE = 28;
  protected static final int LASTUPDATEDBY = 29;
  protected static final int LASTUPDATEDATE = 30;
  protected static final int LASTUPDATELOGIN = 31;
  protected static final int REQUESTID = 32;
  protected static final int PROGRAMAPPLICATIONID = 33;
  protected static final int PROGRAMID = 34;
  protected static final int PROGRAMUPDATEDATE = 35;
  protected static final int CONTRACTOTHERCUSTSID = 36;
  protected static final int VDMSINTERFACEFLAG = 37;
  protected static final int VDMSINTERFACEDATE = 38;
  protected static final int XXCSODESTINATIONSEO = 39;
  protected static final int XXCSOCONTRACTOTHERCUSTSEO = 40;




































  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoContractManagementsEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoContractManagementsEO");
    }
    return mDefinitionObject;
  }








































  /*****************************************************************************
   * エンティティエキスパートインスタンスの取得処理です。
   * @param txn OADBTransactionインスタンス
   *****************************************************************************
   */
  public static XxcsoCommonEntityExpert getXxcsoCommonEntityExpert(
    OADBTransaction txn
  )
  {
    return
      (XxcsoCommonEntityExpert)
        txn.getExpert(XxcsoContractManagementsEOImpl.getDefinitionObject());
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
    // 仮の値を設定します。
    setContractManagementId(new Number(-1));

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

    String contractNumber = getContractNumber();
    
    try
    {
      super.lockRow();
    }
    catch ( AlreadyLockedException ale )
    {
      throw XxcsoMessage.createTransactionLockError(
        XxcsoConstants.TOKEN_VALUE_CONTRACT_NUMBER
          + contractNumber
      );
    }
    catch ( RowInconsistentException rie )
    {
      throw XxcsoMessage.createTransactionInconsistentError(
        XxcsoConstants.TOKEN_VALUE_CONTRACT_NUMBER
          + contractNumber
      );      
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError(
        XxcsoConstants.TOKEN_VALUE_CONTRACT_NUMBER
          + contractNumber
      );      
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード作成処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
    if ( expert == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCommonEntityExpert");
    }

    // 契約書番号を払い出します。
    Date currentDate = expert.getOnlineSysdate();
    String contractNumber
      = expert.getAutoAssignedCode(
          "2"
         ,""
         ,currentDate
        );

    // 登録する直前でシーケンス値を払い出します。
    Number contractManagementId
      = getOADBTransaction().getSequenceValue("XXCSO_CONTRACT_MANAGEMENTS_S01");

    setContractManagementId(contractManagementId);
    setContractNumber(contractNumber);
    super.insertRow();

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

    super.updateRow();

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

// 2010-02-09 [E_本稼動_01538] Mod Start
  /*****************************************************************************
   * コミット前処理です。
   * 保存時処理をCallします。
   * @see oracle.jbo.server.TransactionListener.beforeCommit
   *****************************************************************************
   */
  public void beforeCommit(TransactionEvent e)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    StringBuffer sql = new StringBuffer(300);
      
    sql.append("BEGIN xxcso_010003j_pkg.reflect_contract_status(");
    sql.append("  iv_contract_management_id => :1");
    sql.append(" ,iv_account_number         => :2");
    sql.append(" ,iv_status                 => :3");
    sql.append(" ,ov_errbuf                 => :4");
    sql.append(" ,ov_retcode                => :5");
    sql.append(" ,ov_errmsg                 => :6");
    sql.append(");");
    sql.append("END;");

    CallableStatement stmt = null;
      
    try
    {
      stmt = txn.createCallableStatement(sql.toString(), 0);

      stmt.setString(1, getContractManagementId().stringValue());
      stmt.setString(2, getInstallAccountNumber());
      stmt.setString(3, getStatus());
      stmt.registerOutParameter(4, OracleTypes.VARCHAR);
      stmt.registerOutParameter(5, OracleTypes.VARCHAR);
      stmt.registerOutParameter(6, OracleTypes.VARCHAR);

      stmt.execute();

      String errBuf   = stmt.getString(4);
      String retCode  = stmt.getString(5);
      String errMsg   = stmt.getString(6);

      if ( "1".equals(retCode) )
      {
        XxcsoUtils.unexpected(txn, errBuf);
        throw
          XxcsoMessage.createAssociateErrorMessage(
            XxcsoConstants.TOKEN_VALUE_CONTRACT_REGIST
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoConstants.TOKEN_VALUE_DECISION
           ,errBuf
          );
      }

      if ( "2".equals(retCode) )
      {
        XxcsoUtils.unexpected(txn, errBuf);
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_CONTRACT_REGIST
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoConstants.TOKEN_VALUE_DECISION
           ,errBuf
          );
      }
    }
    catch ( SQLException sqle )
    {
      XxcsoUtils.unexpected(txn, sqle);
      throw
        XxcsoMessage.createSqlErrorMessage(
          sqle,
          XxcsoConstants.TOKEN_VALUE_CONTRACT_REGIST
            + XxcsoConstants.TOKEN_VALUE_DELIMITER1
            + XxcsoConstants.TOKEN_VALUE_DECISION
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
// 2010-02-09 [E_本稼動_01538] Mod End
  
  /**
   * 
   * Gets the attribute value for ContractManagementId, using the alias name ContractManagementId
   */
  public Number getContractManagementId()
  {
    return (Number)getAttributeInternal(CONTRACTMANAGEMENTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractManagementId
   */
  public void setContractManagementId(Number value)
  {
    setAttributeInternal(CONTRACTMANAGEMENTID, value);
  }

  /**
   * 
   * Gets the attribute value for ContractNumber, using the alias name ContractNumber
   */
  public String getContractNumber()
  {
    return (String)getAttributeInternal(CONTRACTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractNumber
   */
  public void setContractNumber(String value)
  {
    setAttributeInternal(CONTRACTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for ContractFormat, using the alias name ContractFormat
   */
  public String getContractFormat()
  {
    return (String)getAttributeInternal(CONTRACTFORMAT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractFormat
   */
  public void setContractFormat(String value)
  {
    setAttributeInternal(CONTRACTFORMAT, value);
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
   * Gets the attribute value for EmployeeNumber, using the alias name EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
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
   * Gets the attribute value for ContractEffectDate, using the alias name ContractEffectDate
   */
  public Date getContractEffectDate()
  {
    return (Date)getAttributeInternal(CONTRACTEFFECTDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractEffectDate
   */
  public void setContractEffectDate(Date value)
  {
    setAttributeInternal(CONTRACTEFFECTDATE, value);
  }

  /**
   * 
   * Gets the attribute value for TransferMonthCode, using the alias name TransferMonthCode
   */
  public String getTransferMonthCode()
  {
    return (String)getAttributeInternal(TRANSFERMONTHCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TransferMonthCode
   */
  public void setTransferMonthCode(String value)
  {
    setAttributeInternal(TRANSFERMONTHCODE, value);
  }

  /**
   * 
   * Gets the attribute value for TransferDayCode, using the alias name TransferDayCode
   */
  public String getTransferDayCode()
  {
    return (String)getAttributeInternal(TRANSFERDAYCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for TransferDayCode
   */
  public void setTransferDayCode(String value)
  {
    setAttributeInternal(TRANSFERDAYCODE, value);
  }

  /**
   * 
   * Gets the attribute value for CloseDayCode, using the alias name CloseDayCode
   */
  public String getCloseDayCode()
  {
    return (String)getAttributeInternal(CLOSEDAYCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CloseDayCode
   */
  public void setCloseDayCode(String value)
  {
    setAttributeInternal(CLOSEDAYCODE, value);
  }

  /**
   * 
   * Gets the attribute value for ContractPeriod, using the alias name ContractPeriod
   */
  public Number getContractPeriod()
  {
    return (Number)getAttributeInternal(CONTRACTPERIOD);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractPeriod
   */
  public void setContractPeriod(Number value)
  {
    setAttributeInternal(CONTRACTPERIOD, value);
  }

  /**
   * 
   * Gets the attribute value for CancellationOfferCode, using the alias name CancellationOfferCode
   */
  public String getCancellationOfferCode()
  {
    return (String)getAttributeInternal(CANCELLATIONOFFERCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CancellationOfferCode
   */
  public void setCancellationOfferCode(String value)
  {
    setAttributeInternal(CANCELLATIONOFFERCODE, value);
  }

  /**
   * 
   * Gets the attribute value for ContractCustomerId, using the alias name ContractCustomerId
   */
  public Number getContractCustomerId()
  {
    return (Number)getAttributeInternal(CONTRACTCUSTOMERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractCustomerId
   */
  public void setContractCustomerId(Number value)
  {
    setAttributeInternal(CONTRACTCUSTOMERID, value);
  }

  /**
   * 
   * Gets the attribute value for InstallAccountId, using the alias name InstallAccountId
   */
  public Number getInstallAccountId()
  {
    return (Number)getAttributeInternal(INSTALLACCOUNTID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallAccountId
   */
  public void setInstallAccountId(Number value)
  {
    setAttributeInternal(INSTALLACCOUNTID, value);
  }

  /**
   * 
   * Gets the attribute value for InstallAccountNumber, using the alias name InstallAccountNumber
   */
  public String getInstallAccountNumber()
  {
    return (String)getAttributeInternal(INSTALLACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallAccountNumber
   */
  public void setInstallAccountNumber(String value)
  {
    setAttributeInternal(INSTALLACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for InstallPartyName, using the alias name InstallPartyName
   */
  public String getInstallPartyName()
  {
    return (String)getAttributeInternal(INSTALLPARTYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallPartyName
   */
  public void setInstallPartyName(String value)
  {
    setAttributeInternal(INSTALLPARTYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for InstallPostalCode, using the alias name InstallPostalCode
   */
  public String getInstallPostalCode()
  {
    return (String)getAttributeInternal(INSTALLPOSTALCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallPostalCode
   */
  public void setInstallPostalCode(String value)
  {
    setAttributeInternal(INSTALLPOSTALCODE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallState, using the alias name InstallState
   */
  public String getInstallState()
  {
    return (String)getAttributeInternal(INSTALLSTATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallState
   */
  public void setInstallState(String value)
  {
    setAttributeInternal(INSTALLSTATE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallCity, using the alias name InstallCity
   */
  public String getInstallCity()
  {
    return (String)getAttributeInternal(INSTALLCITY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallCity
   */
  public void setInstallCity(String value)
  {
    setAttributeInternal(INSTALLCITY, value);
  }

  /**
   * 
   * Gets the attribute value for InstallAddress1, using the alias name InstallAddress1
   */
  public String getInstallAddress1()
  {
    return (String)getAttributeInternal(INSTALLADDRESS1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallAddress1
   */
  public void setInstallAddress1(String value)
  {
    setAttributeInternal(INSTALLADDRESS1, value);
  }

  /**
   * 
   * Gets the attribute value for InstallAddress2, using the alias name InstallAddress2
   */
  public String getInstallAddress2()
  {
    return (String)getAttributeInternal(INSTALLADDRESS2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallAddress2
   */
  public void setInstallAddress2(String value)
  {
    setAttributeInternal(INSTALLADDRESS2, value);
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
   * Gets the attribute value for InstallLocation, using the alias name InstallLocation
   */
  public String getInstallLocation()
  {
    return (String)getAttributeInternal(INSTALLLOCATION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallLocation
   */
  public void setInstallLocation(String value)
  {
    setAttributeInternal(INSTALLLOCATION, value);
  }

  /**
   * 
   * Gets the attribute value for PublishDeptCode, using the alias name PublishDeptCode
   */
  public String getPublishDeptCode()
  {
    return (String)getAttributeInternal(PUBLISHDEPTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for PublishDeptCode
   */
  public void setPublishDeptCode(String value)
  {
    setAttributeInternal(PUBLISHDEPTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for InstallCode, using the alias name InstallCode
   */
  public String getInstallCode()
  {
    return (String)getAttributeInternal(INSTALLCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for InstallCode
   */
  public void setInstallCode(String value)
  {
    setAttributeInternal(INSTALLCODE, value);
  }

  /**
   * 
   * Gets the attribute value for CooperateFlag, using the alias name CooperateFlag
   */
  public String getCooperateFlag()
  {
    return (String)getAttributeInternal(COOPERATEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for CooperateFlag
   */
  public void setCooperateFlag(String value)
  {
    setAttributeInternal(COOPERATEFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for BatchProcStatus, using the alias name BatchProcStatus
   */
  public String getBatchProcStatus()
  {
    return (String)getAttributeInternal(BATCHPROCSTATUS);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for BatchProcStatus
   */
  public void setBatchProcStatus(String value)
  {
    setAttributeInternal(BATCHPROCSTATUS, value);
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

  /**
   * 
   * Gets the attribute value for ContractOtherCustsId, using the alias name ContractOtherCustsId
   */
  public Number getContractOtherCustsId()
  {
    return (Number)getAttributeInternal(CONTRACTOTHERCUSTSID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ContractOtherCustsId
   */
  public void setContractOtherCustsId(Number value)
  {
    setAttributeInternal(CONTRACTOTHERCUSTSID, value);
  }

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTMANAGEMENTID:
        return getContractManagementId();
      case CONTRACTNUMBER:
        return getContractNumber();
      case CONTRACTFORMAT:
        return getContractFormat();
      case STATUS:
        return getStatus();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case CONTRACTEFFECTDATE:
        return getContractEffectDate();
      case TRANSFERMONTHCODE:
        return getTransferMonthCode();
      case TRANSFERDAYCODE:
        return getTransferDayCode();
      case CLOSEDAYCODE:
        return getCloseDayCode();
      case CONTRACTPERIOD:
        return getContractPeriod();
      case CANCELLATIONOFFERCODE:
        return getCancellationOfferCode();
      case CONTRACTCUSTOMERID:
        return getContractCustomerId();
      case INSTALLACCOUNTID:
        return getInstallAccountId();
      case INSTALLACCOUNTNUMBER:
        return getInstallAccountNumber();
      case INSTALLPARTYNAME:
        return getInstallPartyName();
      case INSTALLPOSTALCODE:
        return getInstallPostalCode();
      case INSTALLSTATE:
        return getInstallState();
      case INSTALLCITY:
        return getInstallCity();
      case INSTALLADDRESS1:
        return getInstallAddress1();
      case INSTALLADDRESS2:
        return getInstallAddress2();
      case INSTALLDATE:
        return getInstallDate();
      case INSTALLLOCATION:
        return getInstallLocation();
      case PUBLISHDEPTCODE:
        return getPublishDeptCode();
      case INSTALLCODE:
        return getInstallCode();
      case COOPERATEFLAG:
        return getCooperateFlag();
      case BATCHPROCSTATUS:
        return getBatchProcStatus();
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
      case CONTRACTOTHERCUSTSID:
        return getContractOtherCustsId();
      case VDMSINTERFACEFLAG:
        return getVdmsInterfaceFlag();
      case VDMSINTERFACEDATE:
        return getVdmsInterfaceDate();
      case XXCSODESTINATIONSEO:
        return getXxcsoDestinationsEO();
      case XXCSOCONTRACTOTHERCUSTSEO:
        return getXxcsoContractOtherCustsEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case CONTRACTMANAGEMENTID:
        setContractManagementId((Number)value);
        return;
      case CONTRACTNUMBER:
        setContractNumber((String)value);
        return;
      case CONTRACTFORMAT:
        setContractFormat((String)value);
        return;
      case STATUS:
        setStatus((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case CONTRACTEFFECTDATE:
        setContractEffectDate((Date)value);
        return;
      case TRANSFERMONTHCODE:
        setTransferMonthCode((String)value);
        return;
      case TRANSFERDAYCODE:
        setTransferDayCode((String)value);
        return;
      case CLOSEDAYCODE:
        setCloseDayCode((String)value);
        return;
      case CONTRACTPERIOD:
        setContractPeriod((Number)value);
        return;
      case CANCELLATIONOFFERCODE:
        setCancellationOfferCode((String)value);
        return;
      case CONTRACTCUSTOMERID:
        setContractCustomerId((Number)value);
        return;
      case INSTALLACCOUNTID:
        setInstallAccountId((Number)value);
        return;
      case INSTALLACCOUNTNUMBER:
        setInstallAccountNumber((String)value);
        return;
      case INSTALLPARTYNAME:
        setInstallPartyName((String)value);
        return;
      case INSTALLPOSTALCODE:
        setInstallPostalCode((String)value);
        return;
      case INSTALLSTATE:
        setInstallState((String)value);
        return;
      case INSTALLCITY:
        setInstallCity((String)value);
        return;
      case INSTALLADDRESS1:
        setInstallAddress1((String)value);
        return;
      case INSTALLADDRESS2:
        setInstallAddress2((String)value);
        return;
      case INSTALLDATE:
        setInstallDate((Date)value);
        return;
      case INSTALLLOCATION:
        setInstallLocation((String)value);
        return;
      case PUBLISHDEPTCODE:
        setPublishDeptCode((String)value);
        return;
      case INSTALLCODE:
        setInstallCode((String)value);
        return;
      case COOPERATEFLAG:
        setCooperateFlag((String)value);
        return;
      case BATCHPROCSTATUS:
        setBatchProcStatus((String)value);
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
      case CONTRACTOTHERCUSTSID:
        setContractOtherCustsId((Number)value);
        return;
      case VDMSINTERFACEFLAG:
        setVdmsInterfaceFlag((String)value);
        return;
      case VDMSINTERFACEDATE:
        setVdmsInterfaceDate((Date)value);
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
  public RowIterator getXxcsoDestinationsEO()
  {
    return (RowIterator)getAttributeInternal(XXCSODESTINATIONSEO);
  }





  /**
   * 
   * Gets the associated entity XxcsoContractOtherCustsEOImpl
   */
  public XxcsoContractOtherCustsEOImpl getXxcsoContractOtherCustsEO()
  {
    return (XxcsoContractOtherCustsEOImpl)getAttributeInternal(XXCSOCONTRACTOTHERCUSTSEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoContractOtherCustsEOImpl
   */
  public void setXxcsoContractOtherCustsEO(XxcsoContractOtherCustsEOImpl value)
  {
    setAttributeInternal(XXCSOCONTRACTOTHERCUSTSEO, value);
  }


  /**
   * 
   * Gets the attribute value for VdmsInterfaceFlag, using the alias name VdmsInterfaceFlag
   */
  public String getVdmsInterfaceFlag()
  {
    return (String)getAttributeInternal(VDMSINTERFACEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for VdmsInterfaceFlag
   */
  public void setVdmsInterfaceFlag(String value)
  {
    setAttributeInternal(VDMSINTERFACEFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for VdmsInterfaceDate, using the alias name VdmsInterfaceDate
   */
  public Date getVdmsInterfaceDate()
  {
    return (Date)getAttributeInternal(VDMSINTERFACEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for VdmsInterfaceDate
   */
  public void setVdmsInterfaceDate(Date value)
  {
    setAttributeInternal(VDMSINTERFACEDATE, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number contractManagementId)
  {
    return new Key(new Object[] {contractManagementId});
  }






































}