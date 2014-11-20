/*============================================================================
* ファイル名 : XxcsoApprovalUserLovVORowImpl
* 概要説明   : 承認者LOVビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-02-20 1.0  SCS小川浩     新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007003j.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 承認者LOVビュー行クラス
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoApprovalUserLovVORowImpl extends OAViewRowImpl 
{


  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int POSITIONNAME = 2;
  protected static final int BASECODE = 3;
  protected static final int BASENAME = 4;
  protected static final int POSITIONSORTCODE = 5;
  protected static final int USERNAME = 6;
  protected static final int BASELINEBASECODE = 7;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoApprovalUserLovVORowImpl()
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

  /**
   * 
   * Gets the attribute value for the calculated attribute PositionName
   */
  public String getPositionName()
  {
    return (String)getAttributeInternal(POSITIONNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PositionName
   */
  public void setPositionName(String value)
  {
    setAttributeInternal(POSITIONNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseCode
   */
  public String getBaseCode()
  {
    return (String)getAttributeInternal(BASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseCode
   */
  public void setBaseCode(String value)
  {
    setAttributeInternal(BASECODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaseName
   */
  public String getBaseName()
  {
    return (String)getAttributeInternal(BASENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaseName
   */
  public void setBaseName(String value)
  {
    setAttributeInternal(BASENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute PositionSortCode
   */
  public String getPositionSortCode()
  {
    return (String)getAttributeInternal(POSITIONSORTCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute PositionSortCode
   */
  public void setPositionSortCode(String value)
  {
    setAttributeInternal(POSITIONSORTCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UserName
   */
  public String getUserName()
  {
    return (String)getAttributeInternal(USERNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UserName
   */
  public void setUserName(String value)
  {
    setAttributeInternal(USERNAME, value);
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
      case POSITIONNAME:
        return getPositionName();
      case BASECODE:
        return getBaseCode();
      case BASENAME:
        return getBaseName();
      case POSITIONSORTCODE:
        return getPositionSortCode();
      case USERNAME:
        return getUserName();
      case BASELINEBASECODE:
        return getBaselineBaseCode();
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
      case POSITIONNAME:
        setPositionName((String)value);
        return;
      case BASECODE:
        setBaseCode((String)value);
        return;
      case BASENAME:
        setBaseName((String)value);
        return;
      case POSITIONSORTCODE:
        setPositionSortCode((String)value);
        return;
      case USERNAME:
        setUserName((String)value);
        return;
      case BASELINEBASECODE:
        setBaselineBaseCode((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute BaselineBaseCode
   */
  public String getBaselineBaseCode()
  {
    return (String)getAttributeInternal(BASELINEBASECODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute BaselineBaseCode
   */
  public void setBaselineBaseCode(String value)
  {
    setAttributeInternal(BASELINEBASECODE, value);
  }
}