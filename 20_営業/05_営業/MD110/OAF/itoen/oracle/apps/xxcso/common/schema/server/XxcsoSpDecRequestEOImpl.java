/*============================================================================
* ファイル名 : XxcsoSpDecRequestEOImpl
* 概要説明   : SP専決要求エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS小川浩     新規作成
* 2009-04-02 1.1  SCS柳平直人   [ST障害T1-0229]SP専決ヘッダID採番方式修正
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.server.TransactionEvent;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.AttributeList;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleTypes;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import com.sun.java.util.collections.Iterator;
import java.sql.CallableStatement;
import java.sql.SQLException;

/*******************************************************************************
 * SP専決要求のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecRequestEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SPDECISIONHEADERID = 0;
  protected static final int APPBASECODE = 1;
  protected static final int OPERATIONMODE = 2;
  protected static final int CREATEDBY = 3;
  protected static final int CREATIONDATE = 4;
  protected static final int LASTUPDATEDBY = 5;
  protected static final int LASTUPDATEDATE = 6;
  protected static final int LASTUPDATELOGIN = 7;
  protected static final int REQUESTID = 8;
  protected static final int PROGRAMAPPLICATIONID = 9;
  protected static final int PROGRAMID = 10;
  protected static final int PROGRAMUPDATEDATE = 11;



  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecRequestEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecRequestEO");
    }
    return mDefinitionObject;
  }







  /*****************************************************************************
   * エンティティの作成処理です。
   * 不要なので空振りします。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }

  
  /*****************************************************************************
   * レコードロック処理です。
   * 不要なので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * エンティティの作成処理です。
   * 不要なので空振りします。
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.create
   *****************************************************************************
   */
  public void insertRow(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");
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

    if ( getSpDecisionHeaderId() == null )
    {
      EntityDefImpl def = XxcsoSpDecisionHeadersVEOImpl.getDefinitionObject();
      Iterator headerIt = def.getAllEntityInstancesIterator(txn);

      while ( headerIt.hasNext() )
      {
        XxcsoSpDecisionHeadersVEOImpl headerEo
          = (XxcsoSpDecisionHeadersVEOImpl)headerIt.next();

        if ( headerEo.getEntityState() == STATUS_NEW )
        {
// 2009-04-02 [ST障害T1-0229] Mod Start
//          setSpDecisionHeaderId(headerEo.getSpDecisionHeaderId());
          Number spDecisionHeaderId = headerEo.getSpDecisionHeaderId();
          if (spDecisionHeaderId.intValue() < 0)
          {
            spDecisionHeaderId
              = getOADBTransaction()
                  .getSequenceValue("XXCSO_SP_DECISION_HEADERS_S01");

            // headerEoに対し設定
            headerEo.setSpDecisionHeaderId(spDecisionHeaderId);

            XxcsoUtils.debug(
              txn
             ,"SP_DECISION_HEADER_ID:getSequence[" + spDecisionHeaderId + "]"
            );
          }
          setSpDecisionHeaderId(spDecisionHeaderId);
// 2009-04-02 [ST障害T1-0229] Mod End
          break;
        }
      }
    }
    
    super.updateRow();
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード削除処理です。
   * 不要なので空振りします。
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
   * コミット前処理です。
   * SP専決保存時処理をCallします。
   * @see oracle.jbo.server.TransactionListener.beforeCommit
   *****************************************************************************
   */
  public void beforeCommit(TransactionEvent e)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    StringBuffer sql = new StringBuffer(100);
    int index = 0;
      
    sql.append("BEGIN xxcso_020001j_pkg.process_request(");
    sql.append("  ov_errbuf  => :").append(++index);
    sql.append(" ,ov_retcode => :").append(++index);
    sql.append(" ,ov_errmsg  => :").append(++index);
    sql.append(");");
    sql.append("END;");

    CallableStatement stmt = null;

    index = 0;
      
    try
    {
      stmt = txn.createCallableStatement(sql.toString(), 0);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);
      stmt.registerOutParameter(++index, OracleTypes.VARCHAR);

      stmt.execute();

      index = 0;
        
      String errBuf   = stmt.getString(++index);
      String retCode  = stmt.getString(++index);
      String errMsg   = stmt.getString(++index);

      if ( "1".equals(retCode) )
      {
        XxcsoUtils.unexpected(txn, errBuf);
        throw
          XxcsoMessage.createAssociateErrorMessage(
            XxcsoConstants.TOKEN_VALUE_FULL_VD_SP_DECISION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoConstants.TOKEN_VALUE_REGIST
           ,errBuf
          );
      }

      if ( "2".equals(retCode) )
      {
        XxcsoUtils.unexpected(txn, errBuf);
        throw
          XxcsoMessage.createCriticalErrorMessage(
            XxcsoConstants.TOKEN_VALUE_FULL_VD_SP_DECISION
              + XxcsoConstants.TOKEN_VALUE_DELIMITER1
              + XxcsoConstants.TOKEN_VALUE_REGIST
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
          XxcsoConstants.TOKEN_VALUE_FULL_VD_SP_DECISION
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
   * Gets the attribute value for OperationMode, using the alias name OperationMode
   */
  public String getOperationMode()
  {
    return (String)getAttributeInternal(OPERATIONMODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for OperationMode
   */
  public void setOperationMode(String value)
  {
    setAttributeInternal(OPERATIONMODE, value);
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
      case APPBASECODE:
        return getAppBaseCode();
      case OPERATIONMODE:
        return getOperationMode();
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
      case APPBASECODE:
        setAppBaseCode((String)value);
        return;
      case OPERATIONMODE:
        setOperationMode((String)value);
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
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(String appBaseCode)
  {
    return new Key(new Object[] {appBaseCode});
  }







}