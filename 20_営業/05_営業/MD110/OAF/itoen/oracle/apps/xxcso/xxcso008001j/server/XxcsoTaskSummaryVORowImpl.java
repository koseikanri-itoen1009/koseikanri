/*============================================================================
* ファイル名 : XxcsoTaskSummaryVORowImpl
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
import oracle.jbo.domain.Date;

/*******************************************************************************
 * スケジュールリージョン（タスク）を検索するためのビュー行クラスです。
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoTaskSummaryVORowImpl extends OAViewRowImpl 
{


  protected static final int DISPDATE = 0;
  protected static final int TASKID = 1;
  protected static final int TASKNAME = 2;
  protected static final int TASKACCOUNTNUMBER = 3;
  protected static final int TASKDATE = 4;
  protected static final int TASKDY = 5;
  protected static final int TASKPLANORRESULT = 6;
  protected static final int TASKDESCRIPTION = 7;
  protected static final int TASKOWNERID = 8;
  protected static final int TASKACTUALENDDATE = 9;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoTaskSummaryVORowImpl()
  {
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute TaskId
   */
  public Number getTaskId()
  {
    return (Number)getAttributeInternal(TASKID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskId
   */
  public void setTaskId(Number value)
  {
    setAttributeInternal(TASKID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute TaskName
   */
  public String getTaskName()
  {
    return (String)getAttributeInternal(TASKNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskName
   */
  public void setTaskName(String value)
  {
    setAttributeInternal(TASKNAME, value);
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












  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case DISPDATE:
        return getDispDate();
      case TASKID:
        return getTaskId();
      case TASKNAME:
        return getTaskName();
      case TASKACCOUNTNUMBER:
        return getTaskAccountNumber();
      case TASKDATE:
        return getTaskDate();
      case TASKDY:
        return getTaskDy();
      case TASKPLANORRESULT:
        return getTaskPlanOrResult();
      case TASKDESCRIPTION:
        return getTaskDescription();
      case TASKOWNERID:
        return getTaskOwnerId();
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
      case DISPDATE:
        setDispDate((String)value);
        return;
      case TASKID:
        setTaskId((Number)value);
        return;
      case TASKNAME:
        setTaskName((String)value);
        return;
      case TASKACCOUNTNUMBER:
        setTaskAccountNumber((String)value);
        return;
      case TASKDATE:
        setTaskDate((String)value);
        return;
      case TASKDY:
        setTaskDy((String)value);
        return;
      case TASKPLANORRESULT:
        setTaskPlanOrResult((String)value);
        return;
      case TASKDESCRIPTION:
        setTaskDescription((String)value);
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
   * Gets the attribute value for the calculated attribute DispDate
   */
  public String getDispDate()
  {
    return (String)getAttributeInternal(DISPDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute DispDate
   */
  public void setDispDate(String value)
  {
    setAttributeInternal(DISPDATE, value);
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
   * Gets the attribute value for the calculated attribute TaskOwnerId
   */
  public String getTaskOwnerId()
  {
    return (String)getAttributeInternal(TASKOWNERID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute TaskOwnerId
   */
  public void setTaskOwnerId(String value)
  {
    setAttributeInternal(TASKOWNERID, value);
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