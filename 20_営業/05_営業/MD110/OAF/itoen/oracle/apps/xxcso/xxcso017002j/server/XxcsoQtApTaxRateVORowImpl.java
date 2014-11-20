/*============================================================================
* �t�@�C���� : XxcsoQtApTaxRateVOImpl
* �T�v����   : �����ŗ��擾�p�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2011-05-17 1.0  SCS�ː��a�K  �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso017002j.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Number;
/*******************************************************************************
 * �����ŗ��擾�̃r���[�s�N���X�ł��B
 * @author  SCS�ː��a�K
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoQtApTaxRateVORowImpl extends OAViewRowImpl 
{
  protected static final int APTAXRATE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoQtApTaxRateVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute ApTaxRate
   */
  public Number getApTaxRate()
  {
    return (Number)getAttributeInternal(APTAXRATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute ApTaxRate
   */
  public void setApTaxRate(Number value)
  {
    setAttributeInternal(APTAXRATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APTAXRATE:
        return getApTaxRate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case APTAXRATE:
        setApTaxRate((Number)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}