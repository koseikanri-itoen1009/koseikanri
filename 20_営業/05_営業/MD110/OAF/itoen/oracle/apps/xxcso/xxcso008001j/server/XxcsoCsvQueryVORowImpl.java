/*============================================================================
* ファイル名 : XxcsoCsvQueryVOImpl
* 概要説明   : 週次活動状況照会／CSV出力Query格納用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-28 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso008001j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * CSV出力Query格納用ビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoCsvQueryVORowImpl extends OAViewRowImpl 
{



  protected static final int EMPLOYEENUMBER = 0;
  protected static final int FULLNAME = 1;
  protected static final int TASKDATE = 2;
  protected static final int TASKDY = 3;
  protected static final int TASKPLANORRESULT = 4;
  protected static final int TASKDESCRIPTION = 5;
  protected static final int POSITIONSORTCODE = 6;
  protected static final int USERID = 7;
  protected static final int DISPDATE = 8;
  protected static final int TASKACCOUNTNUMBER = 9;
  protected static final int TASKACTUALENDDATE = 10;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoCsvQueryVORowImpl()
  {
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
      case TASKDATE:
        return getTaskDate();
      case TASKDY:
        return getTaskDy();
      case TASKPLANORRESULT:
        return getTaskPlanOrResult();
      case TASKDESCRIPTION:
        return getTaskDescription();
      case POSITIONSORTCODE:
        return getPositionSortCode();
      case USERID:
        return getUserId();
      case DISPDATE:
        return getDispDate();
      case TASKACCOUNTNUMBER:
        return getTaskAccountNumber();
      case TASKACTUALENDDATE:
        return getTaskActualEndDate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case TASKACCOUNTNUMBER:
        setTaskAccountNumber((String)value);
        return;
      case TASKACTUALENDDATE:
        setTaskActualEndDate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaskDate
   */
  public String getTaskDate()
  {
    return (String)getAttributeInternal(TASKDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskDate
   */
  public void setTaskDate(String value)
  {
    setAttributeInternal(TASKDATE, value);
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute TaskPlanOrResult
   */
  public String getTaskPlanOrResult()
  {
    return (String)getAttributeInternal(TASKPLANORRESULT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskPlanOrResult
   */
  public void setTaskPlanOrResult(String value)
  {
    setAttributeInternal(TASKPLANORRESULT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaskDescription
   */
  public String getTaskDescription()
  {
    return (String)getAttributeInternal(TASKDESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskDescription
   */
  public void setTaskDescription(String value)
  {
    setAttributeInternal(TASKDESCRIPTION, value);
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
   * Gets the attribute value for the calculated attribute DispDate
   */
  public Date getDispDate()
  {
    return (Date)getAttributeInternal(DISPDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DispDate
   */
  public void setDispDate(Date value)
  {
    setAttributeInternal(DISPDATE, value);
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
   * Gets the attribute value for the calculated attribute TaskDy
   */
  public String getTaskDy()
  {
    return (String)getAttributeInternal(TASKDY);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskDy
   */
  public void setTaskDy(String value)
  {
    setAttributeInternal(TASKDY, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaskAccountNumber
   */
  public String getTaskAccountNumber()
  {
    return (String)getAttributeInternal(TASKACCOUNTNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskAccountNumber
   */
  public void setTaskAccountNumber(String value)
  {
    setAttributeInternal(TASKACCOUNTNUMBER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaskActualEndDate
   */
  public Date getTaskActualEndDate()
  {
    return (Date)getAttributeInternal(TASKACTUALENDDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskActualEndDate
   */
  public void setTaskActualEndDate(Date value)
  {
    setAttributeInternal(TASKACTUALENDDATE, value);
  }



}