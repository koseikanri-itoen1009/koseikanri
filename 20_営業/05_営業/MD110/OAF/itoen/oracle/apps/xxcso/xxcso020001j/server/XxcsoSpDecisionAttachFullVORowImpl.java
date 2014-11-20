/*============================================================================
* ÉtÉ@ÉCÉãñº : XxcsoSpDecisionAttachFullVORowImpl
* äTóvê‡ñæ   : ìYïtìoò^Å^çXêVópÉrÉÖÅ[çsÉNÉâÉX
* ÉoÅ[ÉWÉáÉì : 1.0
*============================================================================
* èCê≥óöó
* ì˙ït       Ver. íSìñé“       èCê≥ì‡óe
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCSè¨êÏç_     êVãKçÏê¨
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.BlobDomain;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * ìYïtÇìoò^Å^çXêVÇ∑ÇÈÇΩÇﬂÇÃÉrÉÖÅ[çsÉNÉâÉXÇ≈Ç∑ÅB
 * @author  SCSè¨êÏç_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionAttachFullVORowImpl extends OAViewRowImpl 
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
  protected static final int FULLNAME = 14;
  protected static final int SELECTFLAG = 15;
  protected static final int EXCERPTREADONLY = 16;
  protected static final int ATTACHSELECTIONRENDER = 17;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionAttachFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSpDecisionAttachesEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionAttachesEOImpl getXxcsoSpDecisionAttachesEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionAttachesEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_ATTACH_ID using the alias name SpDecisionAttachId
   */
  public Number getSpDecisionAttachId()
  {
    return (Number)getAttributeInternal(SPDECISIONATTACHID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_ATTACH_ID using the alias name SpDecisionAttachId
   */
  public void setSpDecisionAttachId(Number value)
  {
    setAttributeInternal(SPDECISIONATTACHID, value);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public Number getSpDecisionHeaderId()
  {
    return (Number)getAttributeInternal(SPDECISIONHEADERID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_HEADER_ID using the alias name SpDecisionHeaderId
   */
  public void setSpDecisionHeaderId(Number value)
  {
    setAttributeInternal(SPDECISIONHEADERID, value);
  }

  /**
   * 
   * Gets the attribute value for FILE_NAME using the alias name FileName
   */
  public String getFileName()
  {
    return (String)getAttributeInternal(FILENAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FILE_NAME using the alias name FileName
   */
  public void setFileName(String value)
  {
    setAttributeInternal(FILENAME, value);
  }

  /**
   * 
   * Gets the attribute value for EXCERPT using the alias name Excerpt
   */
  public String getExcerpt()
  {
    return (String)getAttributeInternal(EXCERPT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for EXCERPT using the alias name Excerpt
   */
  public void setExcerpt(String value)
  {
    setAttributeInternal(EXCERPT, value);
  }

  /**
   * 
   * Gets the attribute value for FILE_DATA using the alias name FileData
   */
  public BlobDomain getFileData()
  {
    return (BlobDomain)getAttributeInternal(FILEDATA);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for FILE_DATA using the alias name FileData
   */
  public void setFileData(BlobDomain value)
  {
    setAttributeInternal(FILEDATA, value);
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
      case FULLNAME:
        return getFullName();
      case SELECTFLAG:
        return getSelectFlag();
      case EXCERPTREADONLY:
        return getExcerptReadOnly();
      case ATTACHSELECTIONRENDER:
        return getAttachSelectionRender();
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
      case FULLNAME:
        setFullName((String)value);
        return;
      case SELECTFLAG:
        setSelectFlag((String)value);
        return;
      case EXCERPTREADONLY:
        setExcerptReadOnly((Boolean)value);
        return;
      case ATTACHSELECTIONRENDER:
        setAttachSelectionRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute FullName
   */
  public String getFullName()
  {
    return (String)getAttributeInternal(FULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute FullName
   */
  public void setFullName(String value)
  {
    setAttributeInternal(FULLNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute SelectFlag
   */
  public String getSelectFlag()
  {
    return (String)getAttributeInternal(SELECTFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectFlag
   */
  public void setSelectFlag(String value)
  {
    setAttributeInternal(SELECTFLAG, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute AttachSelectionRender
   */
  public Boolean getAttachSelectionRender()
  {
    return (Boolean)getAttributeInternal(ATTACHSELECTIONRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute AttachSelectionRender
   */
  public void setAttachSelectionRender(Boolean value)
  {
    setAttributeInternal(ATTACHSELECTIONRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ExcerptReadOnly
   */
  public Boolean getExcerptReadOnly()
  {
    return (Boolean)getAttributeInternal(EXCERPTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ExcerptReadOnly
   */
  public void setExcerptReadOnly(Boolean value)
  {
    setAttributeInternal(EXCERPTREADONLY, value);
  }
}