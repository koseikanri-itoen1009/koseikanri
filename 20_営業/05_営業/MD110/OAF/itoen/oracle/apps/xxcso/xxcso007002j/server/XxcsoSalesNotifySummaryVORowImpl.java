/*============================================================================
* ファイル名 : XxcsoSalesNotifySummaryVORowImpl
* 概要説明   : 商談決定情報通知情報取得用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-09 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso007002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;

/*******************************************************************************
 * 商談決定情報通知情報を取得するためのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoSalesNotifySummaryVORowImpl extends OAViewRowImpl 
{



  protected static final int HEADERHISTORYID = 0;
  protected static final int NOTIFYCOMMENT = 1;
  protected static final int APPRRJCTCOMMENT = 2;
  protected static final int NOTIFYLISTHDRRNRENDER = 3;
  protected static final int APPRRJCTCOMMENTHDRRNRENDER = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoSalesNotifySummaryVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute HeaderHistoryId
   */
  public Number getHeaderHistoryId()
  {
    return (Number)getAttributeInternal(HEADERHISTORYID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute HeaderHistoryId
   */
  public void setHeaderHistoryId(Number value)
  {
    setAttributeInternal(HEADERHISTORYID, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case HEADERHISTORYID:
        return getHeaderHistoryId();
      case NOTIFYCOMMENT:
        return getNotifyComment();
      case APPRRJCTCOMMENT:
        return getApprRjctComment();
      case NOTIFYLISTHDRRNRENDER:
        return getNotifyListHdrRNRender();
      case APPRRJCTCOMMENTHDRRNRENDER:
        return getApprRjctCommentHdrRNRender();
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
      case NOTIFYCOMMENT:
        setNotifyComment((String)value);
        return;
      case APPRRJCTCOMMENT:
        setApprRjctComment((String)value);
        return;
      case NOTIFYLISTHDRRNRENDER:
        setNotifyListHdrRNRender((Boolean)value);
        return;
      case APPRRJCTCOMMENTHDRRNRENDER:
        setApprRjctCommentHdrRNRender((Boolean)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NotifyComment
   */
  public String getNotifyComment()
  {
    return (String)getAttributeInternal(NOTIFYCOMMENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NotifyComment
   */
  public void setNotifyComment(String value)
  {
    setAttributeInternal(NOTIFYCOMMENT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprRjctComment
   */
  public String getApprRjctComment()
  {
    return (String)getAttributeInternal(APPRRJCTCOMMENT);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprRjctComment
   */
  public void setApprRjctComment(String value)
  {
    setAttributeInternal(APPRRJCTCOMMENT, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute NotifyListHdrRNRender
   */
  public Boolean getNotifyListHdrRNRender()
  {
    return (Boolean)getAttributeInternal(NOTIFYLISTHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute NotifyListHdrRNRender
   */
  public void setNotifyListHdrRNRender(Boolean value)
  {
    setAttributeInternal(NOTIFYLISTHDRRNRENDER, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApprRjctCommentHdrRNRender
   */
  public Boolean getApprRjctCommentHdrRNRender()
  {
    return (Boolean)getAttributeInternal(APPRRJCTCOMMENTHDRRNRENDER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApprRjctCommentHdrRNRender
   */
  public void setApprRjctCommentHdrRNRender(Boolean value)
  {
    setAttributeInternal(APPRRJCTCOMMENTHDRRNRENDER, value);
  }
}