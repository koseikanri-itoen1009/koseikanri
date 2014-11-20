/*============================================================================
* ファイル名 : XxcsoEmpSelSummaryVORowImpl
* 概要説明   : 週次活動状況照会／検索用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-06 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 担当者選択リージョンを検索するためのビュー行クラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoEmpSelSummaryVORowImpl extends OAViewRowImpl 
{

  protected static final int SELECTFLG = 0;
  protected static final int USERID = 1;
  protected static final int POSITIONNAME = 2;
  protected static final int FULLNAME = 3;
  protected static final int RESOURCEID = 4;
  protected static final int POSITIONSORTCODE = 5;
  protected static final int EMPLOYEENUMBER = 6;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoEmpSelSummaryVORowImpl()
  {
  }

  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SELECTFLG:
        return getSelectFlg();
      case USERID:
        return getUserId();
      case POSITIONNAME:
        return getPositionName();
      case FULLNAME:
        return getFullName();
      case RESOURCEID:
        return getResourceId();
      case POSITIONSORTCODE:
        return getPositionSortCode();
      case EMPLOYEENUMBER:
        return getEmployeeNumber();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case SELECTFLG:
        setSelectFlg((String)value);
        return;
      case USERID:
        setUserId((Number)value);
        return;
      case POSITIONNAME:
        setPositionName((String)value);
        return;
      case FULLNAME:
        setFullName((String)value);
        return;
      case RESOURCEID:
        setResourceId((Number)value);
        return;
      case POSITIONSORTCODE:
        setPositionSortCode((String)value);
        return;
      case EMPLOYEENUMBER:
        setEmployeeNumber((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute UserId
   */
  public Number getUserId()
  {
    return (Number)getAttributeInternal(USERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UserId
   */
  public void setUserId(Number value)
  {
    setAttributeInternal(USERID, value);
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
   * Gets the attribute value for the calculated attribute ResourceId
   */
  public Number getResourceId()
  {
    return (Number)getAttributeInternal(RESOURCEID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ResourceId
   */
  public void setResourceId(Number value)
  {
    setAttributeInternal(RESOURCEID, value);
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
   * Gets the attribute value for the calculated attribute SelectFlg
   */
  public String getSelectFlg()
  {
    return (String)getAttributeInternal(SELECTFLG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute SelectFlg
   */
  public void setSelectFlg(String value)
  {
    setAttributeInternal(SELECTFLG, value);
  }

















}