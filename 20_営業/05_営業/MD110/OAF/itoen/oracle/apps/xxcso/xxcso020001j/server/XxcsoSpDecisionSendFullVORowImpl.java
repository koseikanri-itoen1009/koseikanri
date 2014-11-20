/*============================================================================
* ÉtÉ@ÉCÉãñº : XxcsoSpDecisionSendFullVORowImpl
* äTóvê‡ñæ   : âÒëóêÊìoò^Å^çXêVópÉrÉÖÅ[çsÉNÉâÉX
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
import oracle.jbo.domain.Date;

/*******************************************************************************
 * âÒëóêÊÇìoò^Å^çXêVÇ∑ÇÈÇΩÇﬂÇÃÉrÉÖÅ[çsÉNÉâÉXÇ≈Ç∑ÅB
 * @author  SCSè¨êÏç_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSendFullVORowImpl extends OAViewRowImpl 
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
  protected static final int LOOKUPCODE = 19;
  protected static final int APPROVALAUTHORITYNAME = 20;
  protected static final int APPROVEUSERNAME = 21;
  protected static final int APPROVEBASESHORTNAME = 22;
  protected static final int APPROVALTYPECODE = 23;
  protected static final int APPRAUTHLEVELNUMBER = 24;
  protected static final int RANGETYPEREADONLY = 25;
  protected static final int APPROVECODEREADONLY = 26;
  protected static final int APPROVALCOMMENTREADONLY = 27;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSendFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSpDecisionSendsEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionSendsEOImpl getXxcsoSpDecisionSendsEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSpDecisionSendsEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for SP_DECISION_SEND_ID using the alias name SpDecisionSendId
   */
  public Number getSpDecisionSendId()
  {
    return (Number)getAttributeInternal(SPDECISIONSENDID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for SP_DECISION_SEND_ID using the alias name SpDecisionSendId
   */
  public void setSpDecisionSendId(Number value)
  {
    setAttributeInternal(SPDECISIONSENDID, value);
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
   * Gets the attribute value for APPROVAL_AUTHORITY_NUMBER using the alias name ApprovalAuthorityNumber
   */
  public String getApprovalAuthorityNumber()
  {
    return (String)getAttributeInternal(APPROVALAUTHORITYNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVAL_AUTHORITY_NUMBER using the alias name ApprovalAuthorityNumber
   */
  public void setApprovalAuthorityNumber(String value)
  {
    setAttributeInternal(APPROVALAUTHORITYNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for RANGE_TYPE using the alias name RangeType
   */
  public String getRangeType()
  {
    return (String)getAttributeInternal(RANGETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for RANGE_TYPE using the alias name RangeType
   */
  public void setRangeType(String value)
  {
    setAttributeInternal(RANGETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for APPROVE_CODE using the alias name ApproveCode
   */
  public String getApproveCode()
  {
    return (String)getAttributeInternal(APPROVECODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVE_CODE using the alias name ApproveCode
   */
  public void setApproveCode(String value)
  {
    setAttributeInternal(APPROVECODE, value);
  }

  /**
   * 
   * Gets the attribute value for WORK_REQUEST_TYPE using the alias name WorkRequestType
   */
  public String getWorkRequestType()
  {
    return (String)getAttributeInternal(WORKREQUESTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for WORK_REQUEST_TYPE using the alias name WorkRequestType
   */
  public void setWorkRequestType(String value)
  {
    setAttributeInternal(WORKREQUESTTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for APPROVAL_STATE_TYPE using the alias name ApprovalStateType
   */
  public String getApprovalStateType()
  {
    return (String)getAttributeInternal(APPROVALSTATETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVAL_STATE_TYPE using the alias name ApprovalStateType
   */
  public void setApprovalStateType(String value)
  {
    setAttributeInternal(APPROVALSTATETYPE, value);
  }

  /**
   * 
   * Gets the attribute value for APPROVAL_DATE using the alias name ApprovalDate
   */
  public Date getApprovalDate()
  {
    return (Date)getAttributeInternal(APPROVALDATE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVAL_DATE using the alias name ApprovalDate
   */
  public void setApprovalDate(Date value)
  {
    setAttributeInternal(APPROVALDATE, value);
  }

  /**
   * 
   * Gets the attribute value for APPROVAL_CONTENT using the alias name ApprovalContent
   */
  public String getApprovalContent()
  {
    return (String)getAttributeInternal(APPROVALCONTENT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVAL_CONTENT using the alias name ApprovalContent
   */
  public void setApprovalContent(String value)
  {
    setAttributeInternal(APPROVALCONTENT, value);
  }

  /**
   * 
   * Gets the attribute value for APPROVAL_COMMENT using the alias name ApprovalComment
   */
  public String getApprovalComment()
  {
    return (String)getAttributeInternal(APPROVALCOMMENT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVAL_COMMENT using the alias name ApprovalComment
   */
  public void setApprovalComment(String value)
  {
    setAttributeInternal(APPROVALCOMMENT, value);
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
      case LOOKUPCODE:
        return getLookupCode();
      case APPROVALAUTHORITYNAME:
        return getApprovalAuthorityName();
      case APPROVEUSERNAME:
        return getApproveUserName();
      case APPROVEBASESHORTNAME:
        return getApproveBaseShortName();
      case APPROVALTYPECODE:
        return getApprovalTypeCode();
      case APPRAUTHLEVELNUMBER:
        return getApprAuthLevelNumber();
      case RANGETYPEREADONLY:
        return getRangeTypeReadOnly();
      case APPROVECODEREADONLY:
        return getApproveCodeReadOnly();
      case APPROVALCOMMENTREADONLY:
        return getApprovalCommentReadOnly();
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
      case LOOKUPCODE:
        setLookupCode((String)value);
        return;
      case APPROVALAUTHORITYNAME:
        setApprovalAuthorityName((String)value);
        return;
      case APPROVEUSERNAME:
        setApproveUserName((String)value);
        return;
      case APPROVEBASESHORTNAME:
        setApproveBaseShortName((String)value);
        return;
      case APPROVALTYPECODE:
        setApprovalTypeCode((String)value);
        return;
      case APPRAUTHLEVELNUMBER:
        setApprAuthLevelNumber((Number)value);
        return;
      case RANGETYPEREADONLY:
        setRangeTypeReadOnly((Boolean)value);
        return;
      case APPROVECODEREADONLY:
        setApproveCodeReadOnly((Boolean)value);
        return;
      case APPROVALCOMMENTREADONLY:
        setApprovalCommentReadOnly((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LookupCode
   */
  public String getLookupCode()
  {
    return (String)getAttributeInternal(LOOKUPCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LookupCode
   */
  public void setLookupCode(String value)
  {
    setAttributeInternal(LOOKUPCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprovalAuthorityName
   */
  public String getApprovalAuthorityName()
  {
    return (String)getAttributeInternal(APPROVALAUTHORITYNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprovalAuthorityName
   */
  public void setApprovalAuthorityName(String value)
  {
    setAttributeInternal(APPROVALAUTHORITYNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApproveUserName
   */
  public String getApproveUserName()
  {
    return (String)getAttributeInternal(APPROVEUSERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApproveUserName
   */
  public void setApproveUserName(String value)
  {
    setAttributeInternal(APPROVEUSERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApproveBaseShortName
   */
  public String getApproveBaseShortName()
  {
    return (String)getAttributeInternal(APPROVEBASESHORTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApproveBaseShortName
   */
  public void setApproveBaseShortName(String value)
  {
    setAttributeInternal(APPROVEBASESHORTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprovalTypeCode
   */
  public String getApprovalTypeCode()
  {
    return (String)getAttributeInternal(APPROVALTYPECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprovalTypeCode
   */
  public void setApprovalTypeCode(String value)
  {
    setAttributeInternal(APPROVALTYPECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RangeTypeReadOnly
   */
  public Boolean getRangeTypeReadOnly()
  {
    return (Boolean)getAttributeInternal(RANGETYPEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RangeTypeReadOnly
   */
  public void setRangeTypeReadOnly(Boolean value)
  {
    setAttributeInternal(RANGETYPEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApproveCodeReadOnly
   */
  public Boolean getApproveCodeReadOnly()
  {
    return (Boolean)getAttributeInternal(APPROVECODEREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApproveCodeReadOnly
   */
  public void setApproveCodeReadOnly(Boolean value)
  {
    setAttributeInternal(APPROVECODEREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprovalCommentReadOnly
   */
  public Boolean getApprovalCommentReadOnly()
  {
    return (Boolean)getAttributeInternal(APPROVALCOMMENTREADONLY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprovalCommentReadOnly
   */
  public void setApprovalCommentReadOnly(Boolean value)
  {
    setAttributeInternal(APPROVALCOMMENTREADONLY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprAuthLevelNumber
   */
  public Number getApprAuthLevelNumber()
  {
    return (Number)getAttributeInternal(APPRAUTHLEVELNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprAuthLevelNumber
   */
  public void setApprAuthLevelNumber(Number value)
  {
    setAttributeInternal(APPRAUTHLEVELNUMBER, value);
  }









}