/*============================================================================
* �t�@�C���� : XxcsoGetOnlineSysdateVVOImpl
* �T�v����   : �I�����C���������t�擾�r���[�s�N���X
* �o�[�W���� : 1.0
*============================================================================
* �C������
* ���t       Ver. �S����       �C�����e
* ---------- ---- ------------ ----------------------------------------------
* 2008-12-09 1.0  SCS����_     �V�K�쐬
*============================================================================
*/
package itoen.oracle.apps.xxcso.common.schema.server;
import oracle.apps.fnd.framework.server.OAViewRowImpl;
import oracle.jbo.server.AttributeDefImpl;
import oracle.jbo.domain.Date;

/*******************************************************************************
 * �I�����C���������t���擾���邽�߂̃r���[�s�N���X�ł��B
 * @author  SCS����_
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoGetOnlineSysdateVVORowImpl extends OAViewRowImpl 
{
  protected static final int ONLINESYSDATE = 0;

  /**
   * 
   * This is the default constructor (do not remove)
   */
  public XxcsoGetOnlineSysdateVVORowImpl()
  {
  }

  /**
   * 
   * Gets the attribute value for the calculated attribute OnlineSysdate
   */
  public Date getOnlineSysdate()
  {
    return (Date)getAttributeInternal(ONLINESYSDATE);
  }

  /**
   * 
   * Sets <code>value</code> as the attribute value for the calculated attribute OnlineSysdate
   */
  public void setOnlineSysdate(Date value)
  {
    setAttributeInternal(ONLINESYSDATE, value);
  }
  //  Generated method. Do not modify.

  protected Object getAttrInvokeAccessor(int index, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ONLINESYSDATE:
        return getOnlineSysdate();
      default:
        return super.getAttrInvokeAccessor(index, attrDef);
      }
  }
  //  Generated method. Do not modify.

  protected void setAttrInvokeAccessor(int index, Object value, AttributeDefImpl attrDef) throws Exception
  {
    switch (index)
      {
      case ONLINESYSDATE:
        setOnlineSysdate((Date)value);
        return;
      default:
        super.setAttrInvokeAccessor(index, value, attrDef);
        return;
      }
  }
}