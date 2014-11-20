/*============================================================================
* ファイル名 : XxcsoSpDecisionSendInitVORowImpl
* 概要説明   : 回送先初期化用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-27 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 回送先を初期化するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSpDecisionSendInitVORowImpl extends OAViewRowImpl 
{


  protected static final int APPROVALAUTHORITYNUMBER = 0;
  protected static final int APPROVALAUTHORITYNAME = 1;
  protected static final int APPROVALTYPECODE = 2;
  protected static final int WORKREQUESTTYPE = 3;
  protected static final int APPRAUTHLEVELNUMBER = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSpDecisionSendInitVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprovalAuthorityNumber
   */
  public String getApprovalAuthorityNumber()
  {
    return (String)getAttributeInternal(APPROVALAUTHORITYNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprovalAuthorityNumber
   */
  public void setApprovalAuthorityNumber(String value)
  {
    setAttributeInternal(APPROVALAUTHORITYNUMBER, value);
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPROVALAUTHORITYNUMBER:
        return getApprovalAuthorityNumber();
      case APPROVALAUTHORITYNAME:
        return getApprovalAuthorityName();
      case APPROVALTYPECODE:
        return getApprovalTypeCode();
      case WORKREQUESTTYPE:
        return getWorkRequestType();
      case APPRAUTHLEVELNUMBER:
        return getApprAuthLevelNumber();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPROVALAUTHORITYNUMBER:
        setApprovalAuthorityNumber((String)value);
        return;
      case APPROVALAUTHORITYNAME:
        setApprovalAuthorityName((String)value);
        return;
      case APPROVALTYPECODE:
        setApprovalTypeCode((String)value);
        return;
      case WORKREQUESTTYPE:
        setWorkRequestType((String)value);
        return;
      case APPRAUTHLEVELNUMBER:
        setApprAuthLevelNumber((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkRequestType
   */
  public String getWorkRequestType()
  {
    return (String)getAttributeInternal(WORKREQUESTTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkRequestType
   */
  public void setWorkRequestType(String value)
  {
    setAttributeInternal(WORKREQUESTTYPE, value);
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