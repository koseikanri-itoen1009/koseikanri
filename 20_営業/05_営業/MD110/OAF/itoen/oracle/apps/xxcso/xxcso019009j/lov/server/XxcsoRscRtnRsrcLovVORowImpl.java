/*============================================================================
* ファイル名 : XxcsoRscRtnRsrcLovVORowImpl
* 概要説明   : 担当営業員LOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCS富尾和基    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 担当営業員のLOVのビュー行クラスです。
 * @author  SCS富尾和基
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRscRtnRsrcLovVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int EMPLOYEEBASECODE = 2;
  protected static final int BASECODEFLAG = 3;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoRscRtnRsrcLovVORowImpl()
  {
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
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      case FULLNAME:
        return getFullName();
      case EMPLOYEEBASECODE:
        return getEmployeeBaseCode();
      case BASECODEFLAG:
        return getBaseCodeFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case EMPLOYEEBASECODE:
        setEmployeeBaseCode((String)value);
        return;
      case BASECODEFLAG:
        setBaseCodeFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EmployeeBaseCode
   */
  public String getEmployeeBaseCode()
  {
    return (String)getAttributeInternal(EMPLOYEEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EmployeeBaseCode
   */
  public void setEmployeeBaseCode(String value)
  {
    setAttributeInternal(EMPLOYEEBASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCodeFlag
   */
  public String getBaseCodeFlag()
  {
    return (String)getAttributeInternal(BASECODEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCodeFlag
   */
  public void setBaseCodeFlag(String value)
  {
    setAttributeInternal(BASECODEFLAG, value);
  }



}