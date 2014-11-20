/*============================================================================
* �t�@�C���� : XxcsoPvExtractTermSumVORowImpl
* �T�v����   : �p�[�\�i���C�Y�r���[�쐬��ʁ^��������(�V�K�쐬)�r���[�s�I�u�W�F�N�g
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * ��������(�V�K�쐬)���������邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoPvExtractTermSumVORowImpl extends OAViewRowImpl 
{


  protected static final int LOOKUPCODE = 0;
  protected static final int DESCRIPTION = 1;
  protected static final int ATTRIBUTE1 = 2;
  protected static final int ATTRIBUTE2 = 3;
  protected static final int ATTRIBUTE3 = 4;
  protected static final int ATTRIBUTE4 = 5;
  protected static final int ATTRIBUTE5 = 6;
  protected static final int ATTRIBUTE6 = 7;
  protected static final int ATTRIBUTE7 = 8;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoPvExtractTermSumVORowImpl()
  {
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


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case LOOKUPCODE:
        return getLookupCode();
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
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
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
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
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
}