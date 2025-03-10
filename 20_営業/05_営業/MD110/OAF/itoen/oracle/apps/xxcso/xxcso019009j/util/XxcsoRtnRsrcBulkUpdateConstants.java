/*============================================================================
* t@C¼ : XxcsoRtnRsrcBulkUpdateConstants
* Tvà¾   : [gNo/ScÆõêXVæÊ¤ÊÅèlNX
* o[W : 1.3
*============================================================================
* C³ð
* út       Ver. SÒ       C³àe
* ---------- ---- ------------ ----------------------------------------------
* 2009-01-16 1.0  SCSxöaî  VKì¬
* 2009-03-05 1.1  SCSö½¼l  [CT1-034]d¡cÆõG[Î
* 2010-03-23 1.2  SCS¢åã  [E_{Ò®_01942]Ç³_Î
* 2015-09-08 1.3  SCSKË¶aK [E_{Ò®_13307][gêo^æÊdlÏXÎ
*============================================================================
*/
package itoen.oracle.apps.xxcso.xxcso019009j.util;

/*******************************************************************************
 * AhIF[gNo/ScÆõêXVæÊÌÅèlNXÅ·B
 * @author  SCSxöaî
 * @version 1.0
 *******************************************************************************
 */
public class XxcsoRtnRsrcBulkUpdateConstants 
{
  public static final String MODE_FIRE_ACTION        = "FireAction";

  public static final String[] CENTERING_OBJECTS =
  {
// 2010-03-23 [E_{Ò®_01942] Add Start
    "BaseCodeLayout",
// 2010-03-23 [E_{Ò®_01942] Add End
    "ResourceLayout"
  };
  
  public static final String TOKEN_VALUE_PROCESS = "[gNo^cÆõêXV";

// 2010-03-23 [E_{Ò®_01942] Add Start
  public static final String TOKEN_VALUE_BASECODE       = "_bc";
// 2010-03-23 [E_{Ò®_01942] Add End
  public static final String TOKEN_VALUE_EMPLOYEENUMBER = "cÆõR[h";
  public static final String TOKEN_VALUE_ROUTENO        = "[gNo";
  public static final String TOKEN_VALUE_REFLECTMETHOD  = "½fû@";
  public static final String TOKEN_VALUE_ACCOUNTNUMBER  = "ÚqR[h";
  public static final String TOKEN_VALUE_PARTYNAME      = "Úq¼";
  public static final String TOKEN_VALUE_TRGTRESOURCE   = "»S";
  public static final String TOKEN_VALUE_TRGTROUTENO    = "»[gNo";
  public static final String TOKEN_VALUE_NEXTRESOURCE   = "VS";
  public static final String TOKEN_VALUE_NEXTROUTENO    = "V[gNo";
  public static final String TOKEN_VALUE_ACCOUNT_INFO   = "Úqîñ";

  public static final String MAPKEY_ACCOUNTNUMBER       = "ACCOUNTNUMBER";
  public static final String MAPKEY_PARTYNAME           = "PARTYNAME";

  public static final String BOOL_ISRSV                 = "Y";
  public static final String BOOL_ISNOTRSV              = "N";

  public static final String REFLECT_TRGT               = "1";
  public static final String REFLECT_RSV                = "2";
// 2015-09-08 [E_{Ò®_13307] Add Start
  public static final String CUSTOMER_CLASS_14          = "14";
// 2015-09-08 [E_{Ò®_13307] Add End
}