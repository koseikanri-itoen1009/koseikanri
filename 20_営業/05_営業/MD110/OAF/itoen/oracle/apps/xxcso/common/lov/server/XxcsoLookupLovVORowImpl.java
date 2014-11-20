/*============================================================================
* ファイル名 : XxcsoLookupLovVORowImpl
* 概要説明   : クイックコードLOV用ビュー行クラス
* バージョン : 1.0
*============================================================================
* 修正履歴
* 日付       Ver. 担当者       修正内容
* ---------- ---- ------------ ----------------------------------------------
* 2008-11-05 1.0  SCS小川浩    新規作成
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.lov.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * クイックコードから表示するLOVのビュー行クラスです。
 * @author  SCS小川浩
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoLookupLovVORowImpl extends OAViewRowImpl 
{


  protected static final int APPLICATIONSHORTNAME = 0;
  protected static final int VIEWAPPLICATIONSHORTNAME = 1;
  protected static final int LOOKUPTYPE = 2;
  protected static final int LOOKUPCODE = 3;
  protected static final int MEANING = 4;
  protected static final int DESCRIPTION = 5;
  protected static final int ATTRIBUTE1 = 6;
  protected static final int ATTRIBUTE2 = 7;
  protected static final int ATTRIBUTE3 = 8;
  protected static final int ATTRIBUTE4 = 9;
  protected static final int ATTRIBUTE5 = 10;
  protected static final int ATTRIBUTE6 = 11;
  protected static final int ATTRIBUTE7 = 12;
  protected static final int ATTRIBUTE8 = 13;
  protected static final int ATTRIBUTE9 = 14;
  protected static final int ATTRIBUTE10 = 15;
  protected static final int ATTRIBUTE11 = 16;
  protected static final int ATTRIBUTE12 = 17;
  protected static final int ATTRIBUTE13 = 18;
  protected static final int ATTRIBUTE14 = 19;
  protected static final int ATTRIBUTE15 = 20;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoLookupLovVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApplicationShortName
   */
  public String getApplicationShortName()
  {
    return (String)getAttributeInternal(APPLICATIONSHORTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApplicationShortName
   */
  public void setApplicationShortName(String value)
  {
    setAttributeInternal(APPLICATIONSHORTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ViewApplicationShortName
   */
  public String getViewApplicationShortName()
  {
    return (String)getAttributeInternal(VIEWAPPLICATIONSHORTNAME);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ViewApplicationShortName
   */
  public void setViewApplicationShortName(String value)
  {
    setAttributeInternal(VIEWAPPLICATIONSHORTNAME, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LookupType
   */
  public String getLookupType()
  {
    return (String)getAttributeInternal(LOOKUPTYPE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LookupType
   */
  public void setLookupType(String value)
  {
    setAttributeInternal(LOOKUPTYPE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute LookupCode
   */
  public String getLookupCode()
  {
    return (String)getAttributeInternal(LOOKUPCODE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute LookupCode
   */
  public void setLookupCode(String value)
  {
    setAttributeInternal(LOOKUPCODE, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Meaning
   */
  public String getMeaning()
  {
    return (String)getAttributeInternal(MEANING);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Meaning
   */
  public void setMeaning(String value)
  {
    setAttributeInternal(MEANING, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Description
   */
  public String getDescription()
  {
    return (String)getAttributeInternal(DESCRIPTION);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Description
   */
  public void setDescription(String value)
  {
    setAttributeInternal(DESCRIPTION, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute1
   */
  public String getAttribute1()
  {
    return (String)getAttributeInternal(ATTRIBUTE1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute1
   */
  public void setAttribute1(String value)
  {
    setAttributeInternal(ATTRIBUTE1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute2
   */
  public String getAttribute2()
  {
    return (String)getAttributeInternal(ATTRIBUTE2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute2
   */
  public void setAttribute2(String value)
  {
    setAttributeInternal(ATTRIBUTE2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute3
   */
  public String getAttribute3()
  {
    return (String)getAttributeInternal(ATTRIBUTE3);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute3
   */
  public void setAttribute3(String value)
  {
    setAttributeInternal(ATTRIBUTE3, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute4
   */
  public String getAttribute4()
  {
    return (String)getAttributeInternal(ATTRIBUTE4);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute4
   */
  public void setAttribute4(String value)
  {
    setAttributeInternal(ATTRIBUTE4, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute5
   */
  public String getAttribute5()
  {
    return (String)getAttributeInternal(ATTRIBUTE5);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute5
   */
  public void setAttribute5(String value)
  {
    setAttributeInternal(ATTRIBUTE5, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute6
   */
  public String getAttribute6()
  {
    return (String)getAttributeInternal(ATTRIBUTE6);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute6
   */
  public void setAttribute6(String value)
  {
    setAttributeInternal(ATTRIBUTE6, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute7
   */
  public String getAttribute7()
  {
    return (String)getAttributeInternal(ATTRIBUTE7);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute7
   */
  public void setAttribute7(String value)
  {
    setAttributeInternal(ATTRIBUTE7, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute8
   */
  public String getAttribute8()
  {
    return (String)getAttributeInternal(ATTRIBUTE8);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute8
   */
  public void setAttribute8(String value)
  {
    setAttributeInternal(ATTRIBUTE8, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute9
   */
  public String getAttribute9()
  {
    return (String)getAttributeInternal(ATTRIBUTE9);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute9
   */
  public void setAttribute9(String value)
  {
    setAttributeInternal(ATTRIBUTE9, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute10
   */
  public String getAttribute10()
  {
    return (String)getAttributeInternal(ATTRIBUTE10);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute10
   */
  public void setAttribute10(String value)
  {
    setAttributeInternal(ATTRIBUTE10, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute11
   */
  public String getAttribute11()
  {
    return (String)getAttributeInternal(ATTRIBUTE11);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute11
   */
  public void setAttribute11(String value)
  {
    setAttributeInternal(ATTRIBUTE11, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute12
   */
  public String getAttribute12()
  {
    return (String)getAttributeInternal(ATTRIBUTE12);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute12
   */
  public void setAttribute12(String value)
  {
    setAttributeInternal(ATTRIBUTE12, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute13
   */
  public String getAttribute13()
  {
    return (String)getAttributeInternal(ATTRIBUTE13);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute13
   */
  public void setAttribute13(String value)
  {
    setAttributeInternal(ATTRIBUTE13, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute14
   */
  public String getAttribute14()
  {
    return (String)getAttributeInternal(ATTRIBUTE14);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute14
   */
  public void setAttribute14(String value)
  {
    setAttributeInternal(ATTRIBUTE14, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Attribute15
   */
  public String getAttribute15()
  {
    return (String)getAttributeInternal(ATTRIBUTE15);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Attribute15
   */
  public void setAttribute15(String value)
  {
    setAttributeInternal(ATTRIBUTE15, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPLICATIONSHORTNAME:
        return getApplicationShortName();
      case VIEWAPPLICATIONSHORTNAME:
        return getViewApplicationShortName();
      case LOOKUPTYPE:
        return getLookupType();
      case LOOKUPCODE:
        return getLookupCode();
      case MEANING:
        return getMeaning();
      case DESCRIPTION:
        return getDescription();
      case ATTRIBUTE1:
        return getAttribute1();
      case ATTRIBUTE2:
        return getAttribute2();
      case ATTRIBUTE3:
        return getAttribute3();
      case ATTRIBUTE4:
        return getAttribute4();
      case ATTRIBUTE5:
        return getAttribute5();
      case ATTRIBUTE6:
        return getAttribute6();
      case ATTRIBUTE7:
        return getAttribute7();
      case ATTRIBUTE8:
        return getAttribute8();
      case ATTRIBUTE9:
        return getAttribute9();
      case ATTRIBUTE10:
        return getAttribute10();
      case ATTRIBUTE11:
        return getAttribute11();
      case ATTRIBUTE12:
        return getAttribute12();
      case ATTRIBUTE13:
        return getAttribute13();
      case ATTRIBUTE14:
        return getAttribute14();
      case ATTRIBUTE15:
        return getAttribute15();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APPLICATIONSHORTNAME:
        setApplicationShortName((String)value);
        return;
      case VIEWAPPLICATIONSHORTNAME:
        setViewApplicationShortName((String)value);
        return;
      case LOOKUPTYPE:
        setLookupType((String)value);
        return;
      case LOOKUPCODE:
        setLookupCode((String)value);
        return;
      case MEANING:
        setMeaning((String)value);
        return;
      case DESCRIPTION:
        setDescription((String)value);
        return;
      case ATTRIBUTE1:
        setAttribute1((String)value);
        return;
      case ATTRIBUTE2:
        setAttribute2((String)value);
        return;
      case ATTRIBUTE3:
        setAttribute3((String)value);
        return;
      case ATTRIBUTE4:
        setAttribute4((String)value);
        return;
      case ATTRIBUTE5:
        setAttribute5((String)value);
        return;
      case ATTRIBUTE6:
        setAttribute6((String)value);
        return;
      case ATTRIBUTE7:
        setAttribute7((String)value);
        return;
      case ATTRIBUTE8:
        setAttribute8((String)value);
        return;
      case ATTRIBUTE9:
        setAttribute9((String)value);
        return;
      case ATTRIBUTE10:
        setAttribute10((String)value);
        return;
      case ATTRIBUTE11:
        setAttribute11((String)value);
        return;
      case ATTRIBUTE12:
        setAttribute12((String)value);
        return;
      case ATTRIBUTE13:
        setAttribute13((String)value);
        return;
      case ATTRIBUTE14:
        setAttribute14((String)value);
        return;
      case ATTRIBUTE15:
        setAttribute15((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}