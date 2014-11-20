/*============================================================================
* ファイル名 : XxcsoPvDefUpdDfltFlgVORowImpl
* 概要説明   : パーソナライズビュー作成画面／デフォルトフラグ設定ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-22 1.0  SCS柳平直人  新規作成
*============================================================================
*/

package itoen.oracle.apps.xxcso.xxcso012001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * デフォルトフラグを検索／設定するためのビュー行クラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvDefUpdDfltFlgVORowImpl extends OAViewRowImpl 
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
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvDefUpdDfltFlgVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoPvDefEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoPvDefEOImpl getXxcsoPvDefEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoPvDefEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for VIEW_ID using the alias name ViewId
   */
  public Number getViewId()
  {
    return (Number)getAttributeInternal(VIEWID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VIEW_ID using the alias name ViewId
   */
  public void setViewId(Number value)
  {
    setAttributeInternal(VIEWID, value);
  }

  /**
   * 
   * Gets the attribute value for VIEW_NAME using the alias name ViewName
   */
  public String getViewName()
  {
    return (String)getAttributeInternal(VIEWNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VIEW_NAME using the alias name ViewName
   */
  public void setViewName(String value)
  {
    setAttributeInternal(VIEWNAME, value);
  }

  /**
   * 
   * Gets the attribute value for VIEW_SIZE using the alias name ViewSize
   */
  public String getViewSize()
  {
    return (String)getAttributeInternal(VIEWSIZE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VIEW_SIZE using the alias name ViewSize
   */
  public void setViewSize(String value)
  {
    setAttributeInternal(VIEWSIZE, value);
  }

  /**
   * 
   * Gets the attribute value for DEFAULT_FLAG using the alias name DefaultFlag
   */
  public String getDefaultFlag()
  {
    return (String)getAttributeInternal(DEFAULTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DEFAULT_FLAG using the alias name DefaultFlag
   */
  public void setDefaultFlag(String value)
  {
    setAttributeInternal(DEFAULTFLAG, value);
  }

  /**
   * 
   * Gets the attribute value for VIEW_OPEN_CODE using the alias name ViewOpenCode
   */
  public String getViewOpenCode()
  {
    return (String)getAttributeInternal(VIEWOPENCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for VIEW_OPEN_CODE using the alias name ViewOpenCode
   */
  public void setViewOpenCode(String value)
  {
    setAttributeInternal(VIEWOPENCODE, value);
  }

  /**
   * 
   * Gets the attribute value for DESCRIPTION using the alias name Description
   */
  public String getDescription()
  {
    return (String)getAttributeInternal(DESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for DESCRIPTION using the alias name Description
   */
  public void setDescription(String value)
  {
    setAttributeInternal(DESCRIPTION, value);
  }

  /**
   * 
   * Gets the attribute value for EXTRACT_PATTERN_CODE using the alias name ExtractPatternCode
   */
  public String getExtractPatternCode()
  {
    return (String)getAttributeInternal(EXTRACTPATTERNCODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXTRACT_PATTERN_CODE using the alias name ExtractPatternCode
   */
  public void setExtractPatternCode(String value)
  {
    setAttributeInternal(EXTRACTPATTERNCODE, value);
  }

  /**
   * 
   * Gets the attribute value for CREATED_BY using the alias name CreatedBy
   */
  public Number getCreatedBy()
  {
    return (Number)getAttributeInternal(CREATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATED_BY using the alias name CreatedBy
   */
  public void setCreatedBy(Number value)
  {
    setAttributeInternal(CREATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for CREATION_DATE using the alias name CreationDate
   */
  public Date getCreationDate()
  {
    return (Date)getAttributeInternal(CREATIONDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for CREATION_DATE using the alias name CreationDate
   */
  public void setCreationDate(Date value)
  {
    setAttributeInternal(CREATIONDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public Number getLastUpdatedBy()
  {
    return (Number)getAttributeInternal(LASTUPDATEDBY);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATED_BY using the alias name LastUpdatedBy
   */
  public void setLastUpdatedBy(Number value)
  {
    setAttributeInternal(LASTUPDATEDBY, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public Date getLastUpdateDate()
  {
    return (Date)getAttributeInternal(LASTUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_DATE using the alias name LastUpdateDate
   */
  public void setLastUpdateDate(Date value)
  {
    setAttributeInternal(LASTUPDATEDATE, value);
  }

  /**
   * 
   * Gets the attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public Number getLastUpdateLogin()
  {
    return (Number)getAttributeInternal(LASTUPDATELOGIN);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LAST_UPDATE_LOGIN using the alias name LastUpdateLogin
   */
  public void setLastUpdateLogin(Number value)
  {
    setAttributeInternal(LASTUPDATELOGIN, value);
  }

  /**
   * 
   * Gets the attribute value for REQUEST_ID using the alias name RequestId
   */
  public Number getRequestId()
  {
    return (Number)getAttributeInternal(REQUESTID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for REQUEST_ID using the alias name RequestId
   */
  public void setRequestId(Number value)
  {
    setAttributeInternal(REQUESTID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public Number getProgramApplicationId()
  {
    return (Number)getAttributeInternal(PROGRAMAPPLICATIONID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_APPLICATION_ID using the alias name ProgramApplicationId
   */
  public void setProgramApplicationId(Number value)
  {
    setAttributeInternal(PROGRAMAPPLICATIONID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public Number getProgramId()
  {
    return (Number)getAttributeInternal(PROGRAMID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_ID using the alias name ProgramId
   */
  public void setProgramId(Number value)
  {
    setAttributeInternal(PROGRAMID, value);
  }

  /**
   * 
   * Gets the attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
   */
  public Date getProgramUpdateDate()
  {
    return (Date)getAttributeInternal(PROGRAMUPDATEDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for PROGRAM_UPDATE_DATE using the alias name ProgramUpdateDate
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
}