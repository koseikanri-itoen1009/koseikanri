/*============================================================================
* ファイル名 : XxcsoSalesRequestEOImpl
* 概要説明   : 商談決定情報承認依頼エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS小川浩     新規作成
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
import oracle.jbo.server.TransactionEvent;
import oracle.apps.fnd.framework.server.OADBTransaction;
import oracle.jdbc.OracleTypes;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import java.sql.CallableStatement;
import java.sql.SQLException;
import com.sun.java.util.collections.Iterator;

/*******************************************************************************
 * 商談決定情報を承認依頼するためのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRequestEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int HEADERHISTORYID = 0;
  protected static final int LEADID = 1;
  protected static final int OPERATIONMODE = 2;
  protected static final int NOTIFYSUBJECT = 3;
  protected static final int NOTIFYCOMMENT = 4;
  protected static final int CREATEDBY = 5;
  protected static final int CREATIONDATE = 6;
  protected static final int LASTUPDATEDBY = 7;
  protected static final int LASTUPDATEDATE = 8;
  protected static final int LASTUPDATELOGIN = 9;
  protected static final int APPROVALUSERNAME = 10;
  protected static final int REQUESTID = 11;
  protected static final int PROGRAMAPPLICATIONID = 12;
  protected static final int PROGRAMID = 13;
  protected static final int PROGRAMUPDATEDATE = 14;
  protected static final int XXCSOSALESNOTIFIESEO = 15;


























  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesRequestEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesRequestEO");
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
        txn.getExpert(XxcsoSalesRequestEOImpl.getDefinitionObject());
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
    setHeaderHistoryId(new Number(-1));
    setOperationMode(XxcsoConstants.OPERATION_MODE_NORMAL);
    
    XxcsoUtils.debug(txn, "[END]");
  }
  

  /*****************************************************************************
   * レコードロック処理です。
   * ベーステーブルが一時表なので空振りします。
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
   * レコード作成処理です。
   * 操作モードがREQUESTの場合、レコードを作成します。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // REQUESTの場合のみINSERT
    if ( XxcsoConstants.OPERATION_MODE_REQUEST.equals(getOperationMode()) )
    {
      // 登録する直前でシーケンス値を払い出します。
      Number headerHistoryId
        = getOADBTransaction().getSequenceValue(
            "XXCSO_SALES_HEADERS_HIST_S01"
          );

      setHeaderHistoryId(headerHistoryId);

      super.insertRow();
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコード更新処理です。
   * 呼ばれないはずなので、空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.updateRow
   *****************************************************************************
   */
  public void updateRow()
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");
    XxcsoUtils.debug(txn, "[END]");    
  }



  /*****************************************************************************
   * レコード削除処理です。
   * 呼ばれないはずなので、空振りします。
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
   * 操作モードがREQUESTの場合、商談決定情報承認プロシージャをCallします。
   * @see oracle.jbo.server.TransactionListener.beforeCommit
   *****************************************************************************
   */
  public void beforeCommit(TransactionEvent e)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    // REQUESTの場合のみ、承認依頼ワークフローを起動する
    if ( XxcsoConstants.OPERATION_MODE_REQUEST.equals(getOperationMode()) )
    {
      XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
      if ( expert == null )
      {
        throw
          XxcsoMessage.createInstanceLostError("XxcsoCommonEntityExpert");
      }

      String leadNumber = expert.getLeadNumber(getLeadId());
      
      StringBuffer sql = new StringBuffer(100);
      int index = 0;
      
      sql.append("BEGIN xxcso_007003j_pkg.request_sales_approval(");
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

        if ( ! "0".equals(retCode) )
        {
          XxcsoUtils.unexpected(txn, errBuf);
          throw
            XxcsoMessage.createCriticalErrorMessage(
              XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER + leadNumber +
                XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
                XxcsoConstants.TOKEN_VALUE_APPROVAL_REQUEST
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
            XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER + leadNumber +
              XxcsoConstants.TOKEN_VALUE_DELIMITER1 +
              XxcsoConstants.TOKEN_VALUE_APPROVAL_REQUEST
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
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * 承認依頼モードかを確認します。
   *****************************************************************************
   */
  public static boolean isRequestMode(OADBTransaction txn)
  {
    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl def = XxcsoSalesRequestEOImpl.getDefinitionObject();
    Iterator it = def.getAllEntityInstancesIterator(txn);

    boolean mode = false;

    while ( it.hasNext() )
    {
      XxcsoSalesRequestEOImpl eo = (XxcsoSalesRequestEOImpl)it.next();
      if ( eo.getOperationMode() == XxcsoConstants.OPERATION_MODE_REQUEST )
      {
        mode = true;
        break;
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return mode;
  }


  /**
   * 
   * Gets the attribute value for HeaderHistoryId, using the alias name HeaderHistoryId
   */
  public Number getHeaderHistoryId()
  {
    return (Number)getAttributeInternal(HEADERHISTORYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for HeaderHistoryId
   */
  public void setHeaderHistoryId(Number value)
  {
    setAttributeInternal(HEADERHISTORYID, value);
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
   * Gets the attribute value for NotifySubject, using the alias name NotifySubject
   */
  public String getNotifySubject()
  {
    return (String)getAttributeInternal(NOTIFYSUBJECT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NotifySubject
   */
  public void setNotifySubject(String value)
  {
    setAttributeInternal(NOTIFYSUBJECT, value);
  }

  /**
   * 
   * Gets the attribute value for NotifyComment, using the alias name NotifyComment
   */
  public String getNotifyComment()
  {
    return (String)getAttributeInternal(NOTIFYCOMMENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for NotifyComment
   */
  public void setNotifyComment(String value)
  {
    setAttributeInternal(NOTIFYCOMMENT, value);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case HEADERHISTORYID:
        return getHeaderHistoryId();
      case LEADID:
        return getLeadId();
      case OPERATIONMODE:
        return getOperationMode();
      case NOTIFYSUBJECT:
        return getNotifySubject();
      case NOTIFYCOMMENT:
        return getNotifyComment();
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
      case APPROVALUSERNAME:
        return getApprovalUserName();
      case REQUESTID:
        return getRequestId();
      case PROGRAMAPPLICATIONID:
        return getProgramApplicationId();
      case PROGRAMID:
        return getProgramId();
      case PROGRAMUPDATEDATE:
        return getProgramUpdateDate();
      case XXCSOSALESNOTIFIESEO:
        return getXxcsoSalesNotifiesEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case HEADERHISTORYID:
        setHeaderHistoryId((Number)value);
        return;
      case LEADID:
        setLeadId((Number)value);
        return;
      case OPERATIONMODE:
        setOperationMode((String)value);
        return;
      case NOTIFYSUBJECT:
        setNotifySubject((String)value);
        return;
      case NOTIFYCOMMENT:
        setNotifyComment((String)value);
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
      case APPROVALUSERNAME:
        setApprovalUserName((String)value);
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
   * Gets the attribute value for LeadId, using the alias name LeadId
   */
  public Number getLeadId()
  {
    return (Number)getAttributeInternal(LEADID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for LeadId
   */
  public void setLeadId(Number value)
  {
    setAttributeInternal(LEADID, value);
  }





  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoSalesNotifiesEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOSALESNOTIFIESEO);
  }


  /**
   * 
   * Gets the attribute value for ApprovalUserName, using the alias name ApprovalUserName
   */
  public String getApprovalUserName()
  {
    return (String)getAttributeInternal(APPROVALUSERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApprovalUserName
   */
  public void setApprovalUserName(String value)
  {
    setAttributeInternal(APPROVALUSERNAME, value);
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

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number headerHistoryId)
  {
    return new Key(new Object[] {headerHistoryId});
  }

























}