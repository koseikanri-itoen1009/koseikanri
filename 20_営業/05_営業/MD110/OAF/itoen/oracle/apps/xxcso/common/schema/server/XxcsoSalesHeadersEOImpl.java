/*============================================================================
* ファイル名 : XxcsoSalesHeadersEOImpl
* 概要説明   : 商談決定情報ヘッダエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS小川浩     新規作成
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
import oracle.jbo.DMLException;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import com.sun.java.util.collections.Iterator;
import java.sql.SQLException;

/*******************************************************************************
 * 商談決定情報ヘッダのエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesHeadersEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SALESHEADERID = 0;
  protected static final int LEADID = 1;
  protected static final int OTHERCONTENT = 2;
  protected static final int CREATEDBY = 3;
  protected static final int CREATIONDATE = 4;
  protected static final int LASTUPDATEDBY = 5;
  protected static final int LASTUPDATEDATE = 6;
  protected static final int LASTUPDATELOGIN = 7;
  protected static final int REQUESTID = 8;
  protected static final int PROGRAMAPPLICATIONID = 9;
  protected static final int PROGRAMID = 10;
  protected static final int PROGRAMUPDATEDATE = 11;
  protected static final int XXCSOSALESLINESVEO = 12;









































  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesHeadersEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesHeadersEO");
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
        txn.getExpert(XxcsoSalesHeadersEOImpl.getDefinitionObject());
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
    setSalesHeaderId(new Number(-1));

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

    XxcsoCommonEntityExpert expert = getXxcsoCommonEntityExpert(txn);
    if ( expert == null )
    {
      throw
        XxcsoMessage.createInstanceLostError("XxcsoCommonEntityExpert");
    }

    String leadNumber = expert.getLeadNumber(getLeadId());
    
    try
    {
      super.lockRow();
    }
    catch ( AlreadyLockedException ale )
    {
      throw XxcsoMessage.createTransactionLockError(
        XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
          + leadNumber
      );
    }
    catch ( RowInconsistentException rie )
    {
      throw XxcsoMessage.createTransactionInconsistentError(
        XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
          + leadNumber
      );      
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError(
        XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
          + leadNumber
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

    String leadNumber = expert.getLeadNumber(getLeadId());
    
    // 登録する直前でシーケンス値を払い出します。
    Number salesHeaderId
      = getOADBTransaction().getSequenceValue("XXCSO_SALES_HEADERS_S01");

    setSalesHeaderId(salesHeaderId);

    try
    {
      // 商談決定情報は１つの商談に対して１つのため、
      // UNIQUE KEYエラーが発生する
      super.insertRow();
    }
    catch ( DMLException e )
    {
      Object[] exceptions = e.getDetails();
      if ( exceptions != null && exceptions.length > 0 )
      {
        if ( exceptions[0] instanceof SQLException )
        {
          SQLException exception = (SQLException)exceptions[0];
          int code = exception.getErrorCode();
          if ( code == 1 )
          {
            throw XxcsoMessage.createTransactionInconsistentError(
                    XxcsoConstants.TOKEN_VALUE_LEAD_NUMBER
                      + leadNumber
                  );
          }
        }
      }

      XxcsoUtils.unexpected(txn, e);

      throw e;
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



  /*****************************************************************************
   * レコード変更確認処理です。
   *****************************************************************************
   */
  public static boolean isModified(OADBTransaction txn)
  {
    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl def = XxcsoSalesHeadersEOImpl.getDefinitionObject();
    Iterator it = def.getAllEntityInstancesIterator(txn);

    boolean modified = false;

    while ( it.hasNext() )
    {
      XxcsoSalesHeadersEOImpl eo = (XxcsoSalesHeadersEOImpl)it.next();
      if ( eo.getEntityState() != STATUS_UNMODIFIED &&
           eo.getEntityState() != STATUS_INITIALIZED
         )
      {
        XxcsoUtils.debug(
          txn
         ,"headerEo modified" +
            " id:" + eo.getSalesHeaderId() +
            " status:" + eo.getEntityState()
        );
        modified = true;
        break;
      }
    }

    XxcsoUtils.debug(txn, "[END]");

    return modified;
  }



  /**
   * 
   * Gets the attribute value for SalesHeaderId, using the alias name SalesHeaderId
   */
  public Number getSalesHeaderId()
  {
    return (Number)getAttributeInternal(SALESHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SalesHeaderId
   */
  public void setSalesHeaderId(Number value)
  {
    setAttributeInternal(SALESHEADERID, value);
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
      case SALESHEADERID:
        return getSalesHeaderId();
      case LEADID:
        return getLeadId();
      case OTHERCONTENT:
        return getOtherContent();
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
      case XXCSOSALESLINESVEO:
        return getXxcsoSalesLinesVEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SALESHEADERID:
        setSalesHeaderId((Number)value);
        return;
      case LEADID:
        setLeadId((Number)value);
        return;
      case OTHERCONTENT:
        setOtherContent((String)value);
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
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoSalesLinesVEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOSALESLINESVEO);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number salesHeaderId)
  {
    return new Key(new Object[] {salesHeaderId});
  }
















































}