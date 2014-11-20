/*============================================================================
* ÉtÉ@ÉCÉãñº : XxcsoSalesRequestFullVORowImpl
* äTóvê‡ñæ   : è§íkåàíËèÓïÒè≥îFàÀóäèÓïÒìoò^ópÉrÉÖÅ[çsÉNÉâÉX
* ÉoÅ[ÉWÉáÉì : 1.0
*============================================================================
* èCê≥óöó
* ì˙ït       Ver. íSìñé“       èCê≥ì‡óe
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-10 1.0  SCSè¨êÏç_    êVãKçÏê¨
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * è§íkåàíËèÓïÒè≥îFàÀóäèÓïÒÇìoò^Ç∑ÇÈÇΩÇﬂÇÃÉrÉÖÅ[çsÉNÉâÉXÇ≈Ç∑ÅB
 * @author  SCSè¨êÏç_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesRequestFullVORowImpl extends OAViewRowImpl 
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
  protected static final int APPROVALEMPLOYEENUMBER = 11;
  protected static final int APPROVALNAME = 12;
  protected static final int XXCSOSALESNOTIFYFULLVO = 13;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesRequestFullVORowImpl()
  {
  }

  /**
   * 
   * Gets XxcsoSalesRequestEO entity object.
   */
  public itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesRequestEOImpl getXxcsoSalesRequestEO()
  {
    return (itoen.oracle.apps.xxcso.common.schema.server.XxcsoSalesRequestEOImpl)getEntity(0);
  }

  /**
   * 
   * Gets the attribute value for HEADER_HISTORY_ID using the alias name HeaderHistoryId
   */
  public Number getHeaderHistoryId()
  {
    return (Number)getAttributeInternal(HEADERHISTORYID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for HEADER_HISTORY_ID using the alias name HeaderHistoryId
   */
  public void setHeaderHistoryId(Number value)
  {
    setAttributeInternal(HEADERHISTORYID, value);
  }

  /**
   * 
   * Gets the attribute value for LEAD_ID using the alias name LeadId
   */
  public Number getLeadId()
  {
    return (Number)getAttributeInternal(LEADID);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for LEAD_ID using the alias name LeadId
   */
  public void setLeadId(Number value)
  {
    setAttributeInternal(LEADID, value);
  }

  /**
   * 
   * Gets the attribute value for OPERATION_MODE using the alias name OperationMode
   */
  public String getOperationMode()
  {
    return (String)getAttributeInternal(OPERATIONMODE);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for OPERATION_MODE using the alias name OperationMode
   */
  public void setOperationMode(String value)
  {
    setAttributeInternal(OPERATIONMODE, value);
  }

  /**
   * 
   * Gets the attribute value for NOTIFY_SUBJECT using the alias name NotifySubject
   */
  public String getNotifySubject()
  {
    return (String)getAttributeInternal(NOTIFYSUBJECT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NOTIFY_SUBJECT using the alias name NotifySubject
   */
  public void setNotifySubject(String value)
  {
    setAttributeInternal(NOTIFYSUBJECT, value);
  }

  /**
   * 
   * Gets the attribute value for NOTIFY_COMMENT using the alias name NotifyComment
   */
  public String getNotifyComment()
  {
    return (String)getAttributeInternal(NOTIFYCOMMENT);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for NOTIFY_COMMENT using the alias name NotifyComment
   */
  public void setNotifyComment(String value)
  {
    setAttributeInternal(NOTIFYCOMMENT, value);
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
      case APPROVALEMPLOYEENUMBER:
        return getApprovalEmployeeNumber();
      case APPROVALNAME:
        return getApprovalName();
      case XXCSOSALESNOTIFYFULLVO:
        return getXxcsoSalesNotifyFullVO();
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
      case APPROVALEMPLOYEENUMBER:
        setApprovalEmployeeNumber((String)value);
        return;
      case APPROVALNAME:
        setApprovalName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the associated <code>RowIterator</code> using master-detail link XxcsoSalesNotifyFullVO
   */
  public oracle.jbo.RowIterator getXxcsoSalesNotifyFullVO()
  {
    return (oracle.jbo.RowIterator)getAttributeInternal(XXCSOSALESNOTIFYFULLVO);
  }

  /**
   * 
   * Gets the attribute value for APPROVAL_USER_NAME using the alias name ApprovalUserName
   */
  public String getApprovalUserName()
  {
    return (String)getAttributeInternal(APPROVALUSERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as attribute value for APPROVAL_USER_NAME using the alias name ApprovalUserName
   */
  public void setApprovalUserName(String value)
  {
    setAttributeInternal(APPROVALUSERNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprovalEmployeeNumber
   */
  public String getApprovalEmployeeNumber()
  {
    return (String)getAttributeInternal(APPROVALEMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprovalEmployeeNumber
   */
  public void setApprovalEmployeeNumber(String value)
  {
    setAttributeInternal(APPROVALEMPLOYEENUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprovalName
   */
  public String getApprovalName()
  {
    return (String)getAttributeInternal(APPROVALNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprovalName
   */
  public void setApprovalName(String value)
  {
    setAttributeInternal(APPROVALNAME, value);
  }
}