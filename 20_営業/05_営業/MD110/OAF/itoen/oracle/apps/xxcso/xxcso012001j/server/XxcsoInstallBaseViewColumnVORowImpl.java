/*============================================================================
* ファイル名 : XxcsoInstallBaseViewColumnVORowImpl
* 概要説明   : 物件情報汎用検索画面／表示条件取得ビュー行オブジェクト
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-23 1.0  SCS柳平直人  新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * 表示条件を取得するためのビュー行クラス
 * @author  SCS柳平直人
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoInstallBaseViewColumnVORowImpl extends OAViewRowImpl 
{


  protected static final int VIEWCOLUMNID = 0;
  protected static final int VIEWCOLUMNNAME = 1;
  protected static final int VIEWCOLUMNATTRIBUTENAME = 2;
  protected static final int VIEWDATATYPE = 3;
  protected static final int ENABLEFLAG = 4;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoInstallBaseViewColumnVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewColumnId
   */
  public String getViewColumnId()
  {
    return (String)getAttributeInternal(VIEWCOLUMNID);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewColumnId
   */
  public void setViewColumnId(String value)
  {
    setAttributeInternal(VIEWCOLUMNID, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewColumnName
   */
  public String getViewColumnName()
  {
    return (String)getAttributeInternal(VIEWCOLUMNNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewColumnName
   */
  public void setViewColumnName(String value)
  {
    setAttributeInternal(VIEWCOLUMNNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewColumnAttributeName
   */
  public String getViewColumnAttributeName()
  {
    return (String)getAttributeInternal(VIEWCOLUMNATTRIBUTENAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewColumnAttributeName
   */
  public void setViewColumnAttributeName(String value)
  {
    setAttributeInternal(VIEWCOLUMNATTRIBUTENAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewDataType
   */
  public String getViewDataType()
  {
    return (String)getAttributeInternal(VIEWDATATYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewDataType
   */
  public void setViewDataType(String value)
  {
    setAttributeInternal(VIEWDATATYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute EnableFlag
   */
  public String getEnableFlag()
  {
    return (String)getAttributeInternal(ENABLEFLAG);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute EnableFlag
   */
  public void setEnableFlag(String value)
  {
    setAttributeInternal(ENABLEFLAG, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWCOLUMNID:
        return getViewColumnId();
      case VIEWCOLUMNNAME:
        return getViewColumnName();
      case VIEWCOLUMNATTRIBUTENAME:
        return getViewColumnAttributeName();
      case VIEWDATATYPE:
        return getViewDataType();
      case ENABLEFLAG:
        return getEnableFlag();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case VIEWCOLUMNID:
        setViewColumnId((String)value);
        return;
      case VIEWCOLUMNNAME:
        setViewColumnName((String)value);
        return;
      case VIEWCOLUMNATTRIBUTENAME:
        setViewColumnAttributeName((String)value);
        return;
      case VIEWDATATYPE:
        setViewDataType((String)value);
        return;
      case ENABLEFLAG:
        setEnableFlag((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}