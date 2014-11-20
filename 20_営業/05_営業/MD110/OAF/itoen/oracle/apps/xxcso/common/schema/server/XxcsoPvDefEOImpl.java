/*============================================================================
* ファイル名 : XxcsoPvDefEOImpl
* 概要説明   : 汎用検索テーブルエンティティクラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS柳平直人  新規作成
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
import oracle.apps.fnd.framework.server.OADBTransaction;
import itoen.oracle.apps.xxcso.common.util.XxcsoMessage;
import itoen.oracle.apps.xxcso.common.util.XxcsoConstants;
import itoen.oracle.apps.xxcso.common.util.XxcsoUtils;
import oracle.jbo.AlreadyLockedException;
import oracle.jbo.RowNotFoundException;
import oracle.jbo.RowInconsistentException;

/*******************************************************************************
 * 汎用検索テーブルのエンティティクラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvDefEOImpl extends OAPlsqlEntityImpl 
{
  protected static final int VIEWID = 0;
  protected static final int VIEWNAME = 1;
  protected static final int VIEWSIZE = 2;
  protected static final int DEFAULTFLAG = 3;
  protected static final int VIEWOPENCODE = 4;
  protected static final int DESCRIPTION = 5;
  protected static final int EXTRACTPATTERNCODE = 6;
  protected static final int CREATEDBY = 7;
  protected static final int CREATIONDATE = 8;
  protected static final int LASTUPDATEDBY = 9;
  protected static final int LASTUPDATEDATE = 10;
  protected static final int LASTUPDATELOGIN = 11;
  protected static final int REQUESTID = 12;
  protected static final int PROGRAMAPPLICATIONID = 13;
  protected static final int PROGRAMID = 14;
  protected static final int PROGRAMUPDATEDATE = 15;
  protected static final int XXCSOPVVIEWCOLUMNDEFEO = 16;
  protected static final int XXCSOPVSORTCOLUMNDEFEO = 17;
  protected static final int XXCSOPVEXTRACTTERMDEFVEO = 18;

  private static oracle.apps.fnd.framework.server.OAEntityDefImpl mDefinitionObject;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvDefEOImpl()
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
      mDefinitionObject = (oracle.apps.fnd.framework.server.OAEntityDefImpl)EntityDefImpl.findDefObject("itoen.oracle.apps.xxcso.common.schema.server.XxcsoPvDefEO");
    }
    return mDefinitionObject;
  }

  /*****************************************************************************
   * エンティティの作成処理です。
   * @param list 属性リスト
   *****************************************************************************
   */
  public void create(AttributeList list)
  {
    OADBTransaction txn = getOADBTransaction();
    
    XxcsoUtils.debug(txn, "[START]");

    super.create(list);
    // 仮の値を設定します。
    setViewId(new Number(-1));

    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコード作成処理です。
   * @see oracle.apps.fnd.framework.server.OAPlsqlEntityImpl.lockRow
   *****************************************************************************
   */
  public void lockRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 予めエラーメッセージの文言を作成しておく
    StringBuffer sb = new StringBuffer();
    sb.append(XxcsoConstants.TOKEN_VALUE_PV);
    sb.append(XxcsoConstants.TOKEN_VALUE_DELIMITER3);
    sb.append(getViewName());

    try
    {
      super.lockRow();
    }
    catch ( AlreadyLockedException ale )
    {
      throw XxcsoMessage.createTransactionLockError( new String(sb) );
    }
    catch ( RowInconsistentException rie )
    {
      throw XxcsoMessage.createTransactionInconsistentError( new String(sb) );
    }
    catch ( RowNotFoundException rnfe )
    {
      throw XxcsoMessage.createRecordNotFoundError( new String(sb) );
    }
    
    XxcsoUtils.debug(txn, "[END]");
  }

  /*****************************************************************************
   * レコード作成処理です。
   *****************************************************************************
   */
  public void insertRow()
  {
    OADBTransaction txn = getOADBTransaction();

    XxcsoUtils.debug(txn, "[START]");

    // 登録する直前でシーケンス値を払い出します。
    Number viewId
      = getOADBTransaction().getSequenceValue("XXCSO_PV_DEF_S01");

    setViewId(viewId);

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

    super.deleteRow();

    XxcsoUtils.debug(txn, "[END]");
  }


  /**
   * 
   * Gets the attribute value for ViewId, using the alias name ViewId
   */
  public Number getViewId()
  {
    return (Number)getAttributeInternal(VIEWID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ViewId
   */
  public void setViewId(Number value)
  {
    setAttributeInternal(VIEWID, value);
  }

  /**
   * 
   * Gets the attribute value for ViewName, using the alias name ViewName
   */
  public String getViewName()
  {
    return (String)getAttributeInternal(VIEWNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ViewName
   */
  public void setViewName(String value)
  {
    setAttributeInternal(VIEWNAME, value);
  }

  /**
   * 
   * Gets the attribute value for ViewSize, using the alias name ViewSize
   */
  public String getViewSize()
  {
    return (String)getAttributeInternal(VIEWSIZE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ViewSize
   */
  public void setViewSize(String value)
  {
    setAttributeInternal(VIEWSIZE, value);
  }

  /**
   * 
   * Gets the attribute value for DefaultFlag, using the alias name DefaultFlag
   */
  public String getDefaultFlag()
  {
    return (String)getAttributeInternal(DEFAULTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for DefaultFlag
   */
  public void setDefaultFlag(String value)
  {
    setAttributeInternal(DEFAULTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for ViewOpenCode, using the alias name ViewOpenCode
   */
  public String getViewOpenCode()
  {
    return (String)getAttributeInternal(VIEWOPENCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ViewOpenCode
   */
  public void setViewOpenCode(String value)
  {
    setAttributeInternal(VIEWOPENCODE, value);
  }

  /**
   * 
   * Gets the attribute value for Description, using the alias name Description
   */
  public String getDescription()
  {
    return (String)getAttributeInternal(DESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for Description
   */
  public void setDescription(String value)
  {
    setAttributeInternal(DESCRIPTION, value);
  }

  /**
   * 
   * Gets the attribute value for ExtractPatternCode, using the alias name ExtractPatternCode
   */
  public String getExtractPatternCode()
  {
    return (String)getAttributeInternal(EXTRACTPATTERNCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for ExtractPatternCode
   */
  public void setExtractPatternCode(String value)
  {
    setAttributeInternal(EXTRACTPATTERNCODE, value);
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
      case VIEWID:
        return getViewId();
      case VIEWNAME:
        return getViewName();
      case VIEWSIZE:
        return getViewSize();
      case DEFAULTFLAG:
        return getDefaultFlag();
      case VIEWOPENCODE:
        return getViewOpenCode();
      case DESCRIPTION:
        return getDescription();
      case EXTRACTPATTERNCODE:
        return getExtractPatternCode();
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
      case XXCSOPVVIEWCOLUMNDEFEO:
        return getXxcsoPvViewColumnDefEO();
      case XXCSOPVSORTCOLUMNDEFEO:
        return getXxcsoPvSortColumnDefEO();
      case XXCSOPVEXTRACTTERMDEFVEO:
        return getXxcsoPvExtractTermDefVEO();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWID:
        setViewId((Number)value);
        return;
      case VIEWNAME:
        setViewName((String)value);
        return;
      case VIEWSIZE:
        setViewSize((String)value);
        return;
      case DEFAULTFLAG:
        setDefaultFlag((String)value);
        return;
      case VIEWOPENCODE:
        setViewOpenCode((String)value);
        return;
      case DESCRIPTION:
        setDescription((String)value);
        return;
      case EXTRACTPATTERNCODE:
        setExtractPatternCode((String)value);
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
  public RowIterator getXxcsoPvViewColumnDefEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOPVVIEWCOLUMNDEFEO);
  }



  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoPvSortColumnDefEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOPVSORTCOLUMNDEFEO);
  }



  /**
   * 
   * Gets the associated entity oracle.jbo.RowIterator
   */
  public RowIterator getXxcsoPvExtractTermDefVEO()
  {
    return (RowIterator)getAttributeInternal(XXCSOPVEXTRACTTERMDEFVEO);
  }

  /**
   * 
   * Creates a Key object based on given key constituents
   */
  public static Key createPrimaryKey(Number viewId)
  {
    return new Key(new Object[] {viewId});
  }









}