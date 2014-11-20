/*============================================================================
* �t�@�C���� : XxcsoModelTypeSearchLovVORowImpl
* �T�v����   : �p�[�\�i���C�Y�E�r���[�쐬��ʁ^���_����LOV�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-15 1.0  SCS�������l  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso012001j.lov.server;

import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;

/*******************************************************************************
 * �p�[�\�i���C�Y�E�r���[�쐬��ʁ^���_����LOV�r���[�s�N���X
 * @author  SCS�������l
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoModelTypeSearchLovVORowImpl extends OAViewRowImpl 
{



  protected static final int UNNUMBER = 0;
  protected static final int MEANING1 = 1;
  protected static final int MEANING2 = 2;
  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoModelTypeSearchLovVORowImpl()
  {
  }


  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case UNNUMBER:
        return getUnNumber();
      case MEANING1:
        return getMeaning1();
      case MEANING2:
        return getMeaning2();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case UNNUMBER:
        setUnNumber((String)value);
        return;
      case MEANING1:
        setMeaning1((String)value);
        return;
      case MEANING2:
        setMeaning2((String)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }



  /**
   * 
   * Gets the attribute value for the calculated attribute Meaning1
   */
  public String getMeaning1()
  {
    return (String)getAttributeInternal(MEANING1);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Meaning1
   */
  public void setMeaning1(String value)
  {
    setAttributeInternal(MEANING1, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute Meaning2
   */
  public String getMeaning2()
  {
    return (String)getAttributeInternal(MEANING2);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute Meaning2
   */
  public void setMeaning2(String value)
  {
    setAttributeInternal(MEANING2, value);
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute UnNumber
   */
  public String getUnNumber()
  {
    return (String)getAttributeInternal(UNNUMBER);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute UnNumber
   */
  public void setUnNumber(String value)
  {
    setAttributeInternal(UNNUMBER, value);
  }
}