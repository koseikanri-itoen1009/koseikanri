/*============================================================================
* ファイル名 : XxcsoApproveCodeLovVORowImpl
* 概要説明   : 回送先社員番号LOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-18 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso020001j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 回送先社員番号のLOVのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoApproveCodeLovVORowImpl extends OAViewRowImpl 
{


  protected static final int RANGETYPE = 0;
  protected static final int APPROVALTYPECODE = 1;
  protected static final int EMPLOYEENUMBER = 2;
  protected static final int FULLNAME = 3;
  protected static final int WORKBASECODE = 4;
  protected static final int WORKBASESHORTNAME = 5;
  protected static final int RETURNFULLNAME = 6;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoApproveCodeLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute RangeType
   */
  public String getRangeType()
  {
    return (String)getAttributeInternal(RANGETYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute RangeType
   */
  public void setRangeType(String value)
  {
    setAttributeInternal(RANGETYPE, value);
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
   * Gets the attribute value for the calculated attribute EmployeeNumber
   */
  public String getEmployeeNumber()
  {
    return (String)getAttributeInternal(EMPLOYEENUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeNumber
   */
  public void setEmployeeNumber(String value)
  {
    setAttributeInternal(EMPLOYEENUMBER, value);
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
   * Gets the attribute value for the calculated attribute WorkBaseCode
   */
  public String getWorkBaseCode()
  {
    return (String)getAttributeInternal(WORKBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseCode
   */
  public void setWorkBaseCode(String value)
  {
    setAttributeInternal(WORKBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute WorkBaseShortName
   */
  public String getWorkBaseShortName()
  {
    return (String)getAttributeInternal(WORKBASESHORTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute WorkBaseShortName
   */
  public void setWorkBaseShortName(String value)
  {
    setAttributeInternal(WORKBASESHORTNAME, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case RANGETYPE:
        return getRangeType();
      case APPROVALTYPECODE:
        return getApprovalTypeCode();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case WORKBASECODE:
        return getWorkBaseCode();
      case WORKBASESHORTNAME:
        return getWorkBaseShortName();
      case RETURNFULLNAME:
        return getReturnFullName();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case RANGETYPE:
        setRangeType((String)value);
        return;
      case APPROVALTYPECODE:
        setApprovalTypeCode((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case WORKBASECODE:
        setWorkBaseCode((String)value);
        return;
      case WORKBASESHORTNAME:
        setWorkBaseShortName((String)value);
        return;
      case RETURNFULLNAME:
        setReturnFullName((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ReturnFullName
   */
  public String getReturnFullName()
  {
    return (String)getAttributeInternal(RETURNFULLNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ReturnFullName
   */
  public void setReturnFullName(String value)
  {
    setAttributeInternal(RETURNFULLNAME, value);
  }
}