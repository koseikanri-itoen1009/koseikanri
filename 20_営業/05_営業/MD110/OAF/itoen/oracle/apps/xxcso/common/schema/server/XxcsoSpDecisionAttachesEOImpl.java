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
import oracle.jbo.domain.BlobDomain;
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
public class XxcsoSpDecisionAttachesEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int SPDECISIONATTACHID = 0;
  protected static final int SPDECISIONHEADERID = 1;
  protected static final int FILENAME = 2;
  protected static final int EXCERPT = 3;
  protected static final int FILEDATA = 4;
  protected static final int CREATEDBY = 5;
  protected static final int CREATIONDATE = 6;
  protected static final int LASTUPDATEDBY = 7;
  protected static final int LASTUPDATEDATE = 8;
  protected static final int LASTUPDATELOGIN = 9;
  protected static final int REQUESTID = 10;
  protected static final int PROGRAMAPPLICATIONID = 11;
  protected static final int PROGRAMID = 12;
  protected static final int PROGRAMUPDATEDATE = 13;
  protected static final int XXCSOSPDECISIONHEADERSVEO = 14;




  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionAttachesEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionAttachesEO");
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
    EntityDefImpl attachDef
      = XxcsoSpDecisionAttachesEOImpl.getDefinitionObject();
    Iterator attachIt = attachDef.getAllEntityInstancesIterator(txn);

    int minValue = 0;
    
    while( attachIt.hasNext() )
    {
      XxcsoSpDecisionAttachesEOImpl attachEo
        = (XxcsoSpDecisionAttachesEOImpl)attachIt.next();
      int spDecisionAattachId = attachEo.getSpDecisionAttachId().intValue();

      if ( minValue > spDecisionAattachId )
      {
        minValue = spDecisionAattachId;
      }
    }

    minValue--;
    
    XxcsoUtils.debug(txn, "new id:" + minValue);
    
    setSpDecisionAttachId(new Number(minValue));
    
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
    Number spDecisionAttachId
      = getOADBTransaction().getSequenceValue("XXCSO_SP_DECISION_ATTACHES_S01");

    setSpDecisionAttachId(spDecisionAttachId);

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
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.deleteRow
   *****************************************************************************
   */
  public void deleteRow()
  {
    OADBTransaction txn = getOADBTransaction();
    XxcsoUtils.debug(txn, "[START]");

    super.deleteRow();
    
    XxcsoUtils.debug(txn, "[END]");    
  }




  /**
   * 
   * Gets the attribute value for SpDecisionAttachId, using the alias name SpDecisionAttachId
   */
  public Number getSpDecisionAttachId()
  {
    return (Number)getAttributeInternal(SPDECISIONATTACHID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for SpDecisionAttachId
   */
  public void setSpDecisionAttachId(Number value)
  {
    setAttributeInternal(SPDECISIONATTACHID, value);
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
   * Gets the attribute value for FileName, using the alias name FileName
   */
  public String getFileName()
  {
    return (String)getAttributeInternal(FILENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FileName
   */
  public void setFileName(String value)
  {
    setAttributeInternal(FILENAME, value);
  }

  /**
   * 
   * Gets the attribute value for Excerpt, using the alias name Excerpt
   */
  public String getExcerpt()
  {
    return (String)getAttributeInternal(EXCERPT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Excerpt
   */
  public void setExcerpt(String value)
  {
    setAttributeInternal(EXCERPT, value);
  }

  /**
   * 
   * Gets the attribute value for FileData, using the alias name FileData
   */
  public BlobDomain getFileData()
  {
    return (BlobDomain)getAttributeInternal(FILEDATA);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for FileData
   */
  public void setFileData(BlobDomain value)
  {
    setAttributeInternal(FILEDATA, value);
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
      case SPDECISIONATTACHID:
        return getSpDecisionAttachId();
      case SPDECISIONHEADERID:
        return getSpDecisionHeaderId();
      case FILENAME:
        return getFileName();
      case EXCERPT:
        return getExcerpt();
      case FILEDATA:
        return getFileData();
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
      case SPDECISIONATTACHID:
        setSpDecisionAttachId((Number)value);
        return;
      case SPDECISIONHEADERID:
        setSpDecisionHeaderId((Number)value);
        return;
      case FILENAME:
        setFileName((String)value);
        return;
      case EXCERPT:
        setExcerpt((String)value);
        return;
      case FILEDATA:
        setFileData((BlobDomain)value);
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
  public static Key createPrimaryKey(Number spDecisionAttachId)
  {
    return new Key(new Object[] {spDecisionAttachId});
  }




}