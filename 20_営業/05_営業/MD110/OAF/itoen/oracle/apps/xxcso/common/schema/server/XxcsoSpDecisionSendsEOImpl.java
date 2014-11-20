/*============================================================================
* ファイル名 : XxcsoSpDecisionSendsEOImpl
* 概要説明   : SP専決回送先エンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-19 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAPlsqlEntityImpl;
import oracle.jbo.server.EntityDefImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;
import oracle.jbo.Key;
import oracle.jbo.AttributeList;
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import com.sun.java.util.collections.Iterator;

/*******************************************************************************
 * SP専決回送先のエンティティクラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSendsEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SPDECISIONSENDID = 0;
  protected static final int SPDECISIONHEADERID = 1;
  protected static final int APPROVALAUTHORITYNUMBER = 2;
  protected static final int RANGETYPE = 3;
  protected static final int APPROVECODE = 4;
  protected static final int WORKREQUESTTYPE = 5;
  protected static final int APPROVALSTATETYPE = 6;
  protected static final int APPROVALDATE = 7;
  protected static final int APPROVALCONTENT = 8;
  protected static final int APPROVALCOMMENT = 9;
  protected static final int CREATEDBY = 10;
  protected static final int CREATIONDATE = 11;
  protected static final int LASTUPDATEDBY = 12;
  protected static final int LASTUPDATEDATE = 13;
  protected static final int LASTUPDATELOGIN = 14;
  protected static final int REQUESTID = 15;
  protected static final int PROGRAMAPPLICATIONID = 16;
  protected static final int PROGRAMID = 17;
  protected static final int PROGRAMUPDATEDATE = 18;
  protected static final int XXCSOSPDECISIONHEADERSVEO = 19;











  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSendsEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionSendsEO");
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
    
    // 仮の値を設定します。
    EntityDefImpl sendDef = XxcsoSpDecisionSendsEOImpl.getDefinitionObject();
    Iterator sendIt = sendDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( sendIt.hasNext() )
    {
      XxcsoSpDecisionSendsEOImpl sendEo
        = (XxcsoSpDecisionSendsEOImpl)sendIt.next();
      int spDecisionSendId = sendEo.getSpDecisionSendId().intValue();

      if ( minValue > spDecisionSendId )
      {
        minValue = spDecisionSendId;
      }
    }

    minValue--;
    
    XxcsoUtils.debug(txn, "new id:" + minValue);
    
    setSpDecisionSendId(new Number(minValue));
    
    XxcsoUtils.debug(txn, "[END]");
  }


  /*****************************************************************************
   * レコードロック処理です。
   * 子テーブルはロックしないので空振りします。
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
   * @param list 属性リスト
   * @see oracle.apps.fnd.framework.server.OAEntityImpl.insertRow
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    EntityDefImpl headerDef
      = XxcsoSpDecisionHeadersVEOImpl.getDefinitionObject();
    Iterator headerIt = headerDef.getAllEntityInstancesIterator(txn);

    while ( headerIt.hasNext() )
    {
      XxcsoSpDecisionHeadersVEOImpl headerEo
        = (XxcsoSpDecisionHeadersVEOImpl)headerIt.next();

      if ( headerEo.getEntityState() == STATUS_NEW )
      {
        setSpDecisionHeaderId(headerEo.getSpDecisionHeaderId());
        break;
      }
    }
    
    // 登録する直前でシーケンス値を払い出します。
    Number spDecisionSendId
      = getOADBTransaction().getSequenceValue("XXCSO_SP_DECISION_SENDS_S01");

    setSpDecisionSendId(spDecisionSendId);

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
   * ないはずので空振りします。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");
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
   * Gets the attribute value for ApprovalAuthorityNumber, using the alias name ApprovalAuthorityNumber
   */
  public String getApprovalAuthorityNumber()
  {
    return (String)getAttributeInternal(APPROVALAUTHORITYNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApprovalAuthorityNumber
   */
  public void setApprovalAuthorityNumber(String value)
  {
    setAttributeInternal(APPROVALAUTHORITYNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for RangeType, using the alias name RangeType
   */
  public String getRangeType()
  {
    return (String)getAttributeInternal(RANGETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for RangeType
   */
  public void setRangeType(String value)
  {
    setAttributeInternal(RANGETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ApproveCode, using the alias name ApproveCode
   */
  public String getApproveCode()
  {
    return (String)getAttributeInternal(APPROVECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApproveCode
   */
  public void setApproveCode(String value)
  {
    setAttributeInternal(APPROVECODE, value);
  }

  /**
   * 
   * Gets the attribute value for WorkRequestType, using the alias name WorkRequestType
   */
  public String getWorkRequestType()
  {
    return (String)getAttributeInternal(WORKREQUESTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for WorkRequestType
   */
  public void setWorkRequestType(String value)
  {
    setAttributeInternal(WORKREQUESTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ApprovalStateType, using the alias name ApprovalStateType
   */
  public String getApprovalStateType()
  {
    return (String)getAttributeInternal(APPROVALSTATETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApprovalStateType
   */
  public void setApprovalStateType(String value)
  {
    setAttributeInternal(APPROVALSTATETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for ApprovalDate, using the alias name ApprovalDate
   */
  public Date getApprovalDate()
  {
    return (Date)getAttributeInternal(APPROVALDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApprovalDate
   */
  public void setApprovalDate(Date value)
  {
    setAttributeInternal(APPROVALDATE, value);
  }

  /**
   * 
   * Gets the attribute value for ApprovalContent, using the alias name ApprovalContent
   */
  public String getApprovalContent()
  {
    return (String)getAttributeInternal(APPROVALCONTENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApprovalContent
   */
  public void setApprovalContent(String value)
  {
    setAttributeInternal(APPROVALCONTENT, value);
  }

  /**
   * 
   * Gets the attribute value for ApprovalComment, using the alias name ApprovalComment
   */
  public String getApprovalComment()
  {
    return (String)getAttributeInternal(APPROVALCOMMENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ApprovalComment
   */
  public void setApprovalComment(String value)
  {
    setAttributeInternal(APPROVALCOMMENT, value);
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
      case SPDECISIONSENDID:
        return getSpDecisionSendId();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case APPROVALAUTHORITYNUMBER:
        return getApprovalAuthorityNumber();
      case RANGETYPE:
        return getRangeType();
      case APPROVECODE:
        return getApproveCode();
      case WORKREQUESTTYPE:
        return getWorkRequestType();
      case APPROVALSTATETYPE:
        return getApprovalStateType();
      case APPROVALDATE:
        return getApprovalDate();
      case APPROVALCONTENT:
        return getApprovalContent();
      case APPROVALCOMMENT:
        return getApprovalComment();
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
      case XXCSOSPDECISIONHEADERSVEO:
        return getXxcsoSpDecisionHeadersVEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SPDECISIONSENDID:
        setSpDecisionSendId((Number)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case APPROVALAUTHORITYNUMBER:
        setApprovalAuthorityNumber((String)value);
        return;
      case RANGETYPE:
        setRangeType((String)value);
        return;
      case APPROVECODE:
        setApproveCode((String)value);
        return;
      case WORKREQUESTTYPE:
        setWorkRequestType((String)value);
        return;
      case APPROVALSTATETYPE:
        setApprovalStateType((String)value);
        return;
      case APPROVALDATE:
        setApprovalDate((Date)value);
        return;
      case APPROVALCONTENT:
        setApprovalContent((String)value);
        return;
      case APPROVALCOMMENT:
        setApprovalComment((String)value);
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
   * Gets the attribute value for SpDecisionSendId, using the alias name SpDecisionSendId
   */
  public Number getSpDecisionSendId()
  {
    return (Number)getAttributeInternal(SPDECISIONSENDID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionSendId
   */
  public void setSpDecisionSendId(Number value)
  {
    setAttributeInternal(SPDECISIONSENDID, value);
  }


  /**
   * 
   * Gets the associated entity XxcsoSpDecisionHeadersVEOImpl
   */
  public XxcsoSpDecisionHeadersVEOImpl getXxcsoSpDecisionHeadersVEO()
  {
    return (XxcsoSpDecisionHeadersVEOImpl)getAttributeInternal(XXCSOSPDECISIONHEADERSVEO);
  }

  /**
   * 
   * Sets <code>value</code> as the associated entity XxcsoSpDecisionHeadersVEOImpl
   */
  public void setXxcsoSpDecisionHeadersVEO(XxcsoSpDecisionHeadersVEOImpl value)
  {
    setAttributeInternal(XXCSOSPDECISIONHEADERSVEO, value);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number spDecisionSendId)
  {
    return new Key(new Object[] {spDecisionSendId});
  }










}